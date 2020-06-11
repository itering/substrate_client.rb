require "substrate_client/version"

require "logger"
require "scale.rb"
require "json"
require "active_support"
require "active_support/core_ext/string"
require "websocket"
require "helper"
require "timeout_queue"
require "substrate_client_sync"

class SubstrateClient
  class RpcError < StandardError; end
  class RpcTimeout < StandardError; end
  class << self
    attr_accessor :logger
  end
  SubstrateClient.logger = Logger.new(STDOUT)
  SubstrateClient.logger.level = Logger::INFO

  attr_accessor :spec_name, :spec_version, :metadata
  attr_accessor :ws

  def initialize(url, spec_name: nil, onopen: nil)
    @url = url
    @request_id = 1
    @spec_name = spec_name
    @onopen = onopen
    Scale::TypeRegistry.instance.load(spec_name)

    init_ws

    at_exit { self.close }
  end

  def close
    @ws.close
  end

  def request(method, params, callback: nil, subscription_callback: nil)
    payload = {
      "jsonrpc" => "2.0",
      "method" => method,
      "params" => params,
      "id" => @request_id
    }

    while @callbacks.nil?
      sleep(1)
    end

    @callbacks[@request_id] = proc do |data| 
      if not subscription_callback.nil? && data["result"]
        @subscription_callbacks[data["result"]] = subscription_callback
      end

      callback.call data if callback
    end
    @ws.send(payload.to_json)
    @request_id += 1
  end

  def init_runtime(block_hash=nil, &callback)
    # set current runtime spec version
    self.state_get_runtime_version(block_hash) do |runtime_version|
      @spec_version = runtime_version["specVersion"]
      Scale::TypeRegistry.instance.spec_version = @spec_version

      # set current metadata
      self.get_metadata(block_hash) do |metadata|
        @metadata = metadata
        Scale::TypeRegistry.instance.metadata = @metadata.value
        callback.call
      end
    end
  end

  def do_init_runtime(block_hash, &callback)
  end

  def invoke(method, params, callback)
    request method, params, callback: proc { |data|
      if data["error"]
        Thread.main.raise RpcError, data["error"]
      else
        callback.call data["result"] unless callback.nil?
      end
    }
  end

  def rpc_method(method_name)
    Helper.real_method_name(method_name.to_s)
  end

  # ################################################
  # origin rpc methods
  # ################################################
  def method_missing(method, args, &callback)
    rpc_method = Helper.real_method_name(method)
    invoke rpc_method, args, callback
  end

  def state_get_runtime_version(block_hash=nil, &callback)
    invoke rpc_method(__method__), [ block_hash ], callback
  end

  def rpc_methods(&callback)
    invoke rpc_method(__method__), [], callback
  end

  def chain_get_head(&callback)
    invoke rpc_method(__method__), [], callback
  end

  def chain_get_finalised_head(&callback)
    invoke rpc_method(__method__), [], callback
  end

  def chain_get_header(block_hash = nil, &callback)
    invoke rpc_method(__method__), [ block_hash ], callback
  end

  def chain_get_block(block_hash = nil, &callback)
    invoke rpc_method(__method__), [ block_hash ], callback
  end

  def chain_get_block_hash(block_id, &callback)
    invoke rpc_method(__method__), [ block_id ], callback
  end

  def chain_get_runtime_version(block_hash = nil, &callback)
    invoke rpc_method(__method__), [ block_hash ], callback
  end

  def state_get_metadata(block_hash = nil, &callback)
    invoke rpc_method(__method__), [ block_hash ], callback
  end

  def state_get_storage(storage_key, block_hash = nil, &callback)
    invoke rpc_method(__method__), [ storage_key, block_hash ], callback
  end

  def system_name(&callback)
    invoke rpc_method(__method__), [], callback
  end

  def system_version(&callback)
    invoke rpc_method(__method__), [], callback
  end

  def chain_subscribe_all_heads(&callback)
    request rpc_method(__method__), [], subscription_callback: callback
  end

  def chain_unsubscribe_all_heads(subscription)
    invoke rpc_method(__method__), [ subscription ], nil
  end

  def chain_subscribe_new_heads(&callback)
    request rpc_method(__method__), [], subscription_callback: callback
  end

  def chain_unsubscribe_new_heads(subscription)
    invoke rpc_method(__method__), [ subscription ], nil 
  end

  def chain_subscribe_finalized_heads(&callback)
    request rpc_method(__method__), [], subscription_callback: callback
  end

  def chain_unsubscribe_finalized_heads(subscription)
    invoke rpc_method(__method__), [ subscription ], nil
  end

  def state_subscribe_runtime_version(&callback)
    request rpc_method(__method__), [], subscription_callback: callback
  end

  def state_unsubscribe_runtime_version(subscription)
    invoke rpc_method(__method__), [ subscription ], nil
  end

  def state_subscribe_storage(keys, &callback)
    request rpc_method(__method__), [keys], subscription_callback: callback
  end

  def state_unsubscribe_storage(subscription)
    invoke rpc_method(__method__), [ subscription ], nil 
  end

  # ################################################
  # custom methods based on origin rpc methods
  # ################################################
  def method_list(&callback)
    self.rpc_methods do |result|
      callback.call result["methods"].map(&:underscore)
    end
  end

  def get_block_number(block_hash, &callback)
    self.chain_get_header(block_hash) do |header|
      callback.call header["number"].to_i(16)
    end
  end

  def get_metadata(block_hash=nil, &callback)
    self.state_get_metadata(block_hash) do |hex|
      callback.call Scale::Types::Metadata.decode(Scale::Bytes.new(hex))
    end
  end

  def get_block(block_hash=nil, &callback)
    self.init_runtime block_hash do
      self.chain_get_block(block_hash) do |block|
        block = Helper.decode_block block
        callback.call block
      end
    end
  end

  def get_block_events(block_hash=nil, &callback)
    self.init_runtime(block_hash) do
      storage_key =  "0x26aa394eea5630e07c48ae0c9558cef780d41e5e16056765bc8461851072c9d7"
      self.state_get_storage storage_key, block_hash do |events_data|
        scale_bytes = Scale::Bytes.new(events_data)
        events = Scale::Types.get("Vec<EventRecord>").decode(scale_bytes).to_human
        callback.call events
      end
    end
  end

  def subscribe_block_events(&callback)
    self.chain_subscribe_finalized_heads do |data|

      block_number = data["params"]["result"]["number"].to_i(16) - 1
      block_hash = data["params"]["result"]["parentHash"]

      EM.defer(

        proc {
          self.get_block_events block_hash do |events|
            begin
              result = { block_number: block_number, events: events }
              callback.call result
            rescue => ex
              SubstrateClient.logger.error ex.message
              SubstrateClient.logger.error ex.backtrace.join("\n")
            end
          end
        },

        proc { |result| 
        },

        proc { |e|
          SubstrateClient.logger.error e
        }

      )
    end
  end

  def get_storage(module_name, storage_name, params = nil, block_hash = nil, &callback)
    self.init_runtime(block_hash) do
      storage_hash, return_type = Helper.generate_storage_hash_from_metadata(@metadata, module_name, storage_name, params)
      self.state_get_storage(storage_hash, block_hash) do |result|
        if result
          storage = Scale::Types.get(return_type).decode(Scale::Bytes.new(result))
          callback.call storage
        else
          callback.call nil
        end
      end
    end
  end

  def compose_call(module_name, call_name, params, block_hash=nil, &callback)
    self.init_runtime(block_hash) do
      hex = Helper.compose_call_from_metadata(@metadata, module_name, call_name, params)
      callback.call hex
    end
  end

  private
  def init_ws
    @ws = Websocket.new(@url,

      onopen: proc do |event|
        @callbacks = {}
        @subscription_callbacks = {}
        @onopen.call event if not @onopen.nil?
      end,

      onmessage: proc do |event| 
        if event.data.include?("jsonrpc")
          begin
            data = JSON.parse event.data

            if data["params"]
              if @subscription_callbacks[data["params"]["subscription"]]
                @subscription_callbacks[data["params"]["subscription"]].call data
              end
            else
              @callbacks[data["id"]].call data
              @callbacks.delete(data["id"])
            end

          rescue => ex
            SubstrateClient.logger.error ex.message
            SubstrateClient.logger.error ex.backtrace.join("\n")
          end
        end
      end

    )
  end

end
