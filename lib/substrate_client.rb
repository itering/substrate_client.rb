require "substrate_client/version"

require "substrate_common"
require "scale"

require "faye/websocket"
require "eventmachine"
require "json"
require "active_support"
require "active_support/core_ext/string"

def ws_request(url, payload)
  result = nil

  EM.run do
    ws = Faye::WebSocket::Client.new(url)

    ws.on :open do |event|
      # p [:open]
      ws.send(payload.to_json)
    end

    ws.on :message do |event|
      # p [:message, event.data]
      if event.data.include?("jsonrpc")
        result = JSON.parse event.data
        ws.close(3001, "data received")
        EM.stop
      end
    end

    ws.on :close do |event|
      # p [:close, event.code, event.reason]
      ws = nil
    end
  end

  result
end

class SubstrateClient
  attr_accessor :spec_name, :spec_version, :metadata

  def initialize(url)
    @url = url
    @request_id = 1
  end

  # TODO: error
  def request(method, params)
    payload = {
      "jsonrpc" => "2.0",
      "method" => method,
      "params" => params,
      "id" => @request_id
    }
    @request_id += 1
    ws_request(@url, payload)
  end

  # ############################
  # native rpc methods support
  # ############################
  def method_missing(method, *args)
    data = request(SubstrateClient.real_method_name(method), args)
    data["result"]
  end

  # ################################################
  # custom methods wrapped from native rpc methods
  # ################################################
  def method_list
    methods = self.rpc_methods["methods"].map(&:underscore)
    methods << "method_list"
  end

  # TODO: add cache
  def init(block_hash = nil)
    block_runtime_version = self.state_get_runtime_version(block_hash)
    @spec_name = block_runtime_version["specName"]
    @spec_version = block_runtime_version["specVersion"]

    Scale::TypeRegistry.instance.load(spec_name, spec_version)
    @metadata = self.get_metadata(block_hash)
    true
  end

  def get_metadata(block_hash)
    hex = self.state_get_metadata(block_hash)
    Scale::Types::Metadata.decode(Scale::Bytes.new(hex))
  end

  # client.get_storage("Balances", "Account", "0xb8c725ae2dfca19e469628eea1e2523ac75b4b829bb40a27d0dc5c72eaa9f225", "0x6ba283b175e29c1dcbafa311b7b2a6fbfaea1e62a84713dd2808b06665ef3026")
  # client.get_storage("Balances", "Account", ["0x6ce96ae5c300096b09dbd4567b0574f6a1281ae0e5cfe4f6b0233d1821f6206b"])
  def get_storage_at(module_name, storage_function_name, params = nil)

    # TODO: uninit raise a exception
    # find the storage item from metadata
    metadata_modules = @metadata.value.value[:metadata][:modules]
    metadata_module = metadata_modules.detect { |mm| mm[:name] == module_name }
    raise "Module '#{module_name}' not exist" unless metadata_module
    storage_item = metadata_module[:storage][:items].detect { |item| item[:name] == storage_function_name }
    raise "Storage item '#{storage_function_name}' not exist. \n#{metadata_module.inspect}" unless storage_item
    puts metadata_module.inspect

    if return_type = storage_item[:type][:Plain]
      hasher = "Twox64Concat"
    elsif map = storage_item[:type][:Map]
      raise "Storage call of type \"Map\" requires 1 parameter" if params.nil? || params.length != 1

      hasher = map[:hasher]
      return_type = map[:value]
      # TODO: decode to account id if param is address
      # params[0] = decode(params[0]) if map[:key] == "AccountId"
      params[0] = Scale::Types.get(map[:key]).new(params[0]).encode
    elsif map = storage_item[:type][:DoubleMap]
      raise "Storage call of type \"DoubleMapType\" requires 2 parameters" if params.nil? || params.length != 2

      hasher = map[:hasher]
      hasher2 = map[:key2Hasher]
      return_type = map[:value]
      params[0] = Scale::Types.get(map[:key1]).new(params[0]).encode
      params[1] = Scale::Types.get(map[:key2]).new(params[1]).encode
    else
      raise NotImplementedError
    end

    storage_hash = SubstrateClient.generate_storage_hash(
      module_name,
      storage_function_name,
      params,
      hasher,
      hasher2,
      @metadata.value.value[:metadata][:version]
    )

    puts storage_hash

    result = self.state_get_storage_at(storage_hash, block_hash)
    return unless result
    Scale::Types.get(return_type).decode(Scale::Bytes.new(result)).value
  rescue => ex
    puts ex.message
    puts ex.backtrace
  end

  class << self
    def generate_storage_hash(storage_module_name, storage_function_name, params = nil, hasher = nil, hasher2 = nil, metadata_version = nil)
      if metadata_version and metadata_version >= 9
        storage_hash = Crypto.twox128(storage_module_name) + Crypto.twox128(storage_function_name)

        if params
          params.each_with_index do |param, index|
            if index == 0
              param_hasher = hasher
            elsif index == 1
              param_hasher = hasher2
            else
              raise "Unexpected third parameter for storage call"
            end

            param_key = param.hex_to_bytes
            param_hasher = "Twox128" if param_hasher.nil?
            storage_hash += Crypto.send param_hasher.underscore, param_key
          end
        end

        "0x#{storage_hash}"
      else
        # TODO: add test
        storage_hash = storage_module_name + " " + storage_function_name

        unless params.nil?
          params = [params] if params.class != ::Array
          params_key = params.join("")
          hasher = "Twox128" if hasher.nil?
          storage_hash += params_key.hex_to_bytes.bytes_to_utf8 
        end

        "0x#{Crypto.send( hasher.underscore, storage_hash )}"
      end
    end

    # chain_unsubscribe_runtime_version
    # => 
    # chain_unsubscribeRuntimeVersion
    def real_method_name(method_name)
      segments = method_name.to_s.split("_")
      segments[0] + "_" + segments[1] + segments[2..].map(&:capitalize).join
    end

  end


end

