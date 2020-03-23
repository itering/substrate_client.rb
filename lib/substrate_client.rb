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
  attr_accessor :spec_name, :spec_version

  def initialize(url)
    @url = url
    @request_id = 1
  end

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

  def init(block_hash = nil)
    block_runtime_version = self.state_get_runtime_version(block_hash)
    @spec_name = block_runtime_version["specName"]
    @spec_version = block_runtime_version["specVersion"]

    Scale::TypeRegistry.instance.load(spec_name, spec_version)
    @metadata = self.get_metadata(block_hash)
  end

  def get_metadata(block_hash)
    hex = self.state_get_metadata(block_hash)
    Scale::Types::Metadata.decode(Scale::Bytes.new(hex))
  end

  # client.get_storage("Balances", "Account", "0xb8c725ae2dfca19e469628eea1e2523ac75b4b829bb40a27d0dc5c72eaa9f225", "0x6ba283b175e29c1dcbafa311b7b2a6fbfaea1e62a84713dd2808b06665ef3026")
  # client.get_storage("Balances", "TotalIssuance", nil, "0x6ba283b175e29c1dcbafa311b7b2a6fbfaea1e62a84713dd2808b06665ef3026")
  def get_storage_at(module_name, storage_function_name, params = nil, block_hash)
    # TODO: add cache
    init(block_hash)

    # find the storage item from metadata
    metadata_modules = @metadata.value.value[:metadata][:modules]
    metadata_module = metadata_modules.detect { |mm| mm[:name] == module_name }
    raise "Module '#{module_name}' not exist" unless metadata_module
    storage_item = metadata_module[:storage][:items].detect { |item| item[:name] == storage_function_name }

    if return_type = storage_item[:type][:Plain]
      hasher = "xxhash_128"
    elsif map = storage_item[:type][:Map]
      params = [params] if params.class != ::Array
      raise "Storage call of type \"Map\" requires 1 parameter" if params.nil? || params.length != 1

      # Identity
      hasher = "xxhash_128" if map[:hasher] == "Twox64Concat"
      hasher = "black2_256" if map[:hasher] == "Blake2_128Concat"
      return_type = map[:value]

      # TODO: decode to account id if param is address
      # if map[:key] == "AccountId"
        # params[0] = decode(params[0])
      # end
      params[0] = Scale::Types.get(map[:key]).new(params[0]).encode
    else
      raise NotImplementedError
    end

    storage_hash = SubstrateClient.generate_storage_hash(
      module_name,
      storage_function_name,
      params,
      hasher,
      @metadata.value.value[:metadata][:version]
    )

    result = self.state_get_storage_at(storage_hash, block_hash)
    return unless result
    Scale::Types.get(return_type).decode(Scale::Bytes.new(result)).value
  rescue => ex
    puts ex.message
    puts ex.backtrace
  end

  class << self
    # hasher: 'xxhash_128', 'black2_256'
    def generate_storage_hash(storage_module_name, storage_function_name, params = nil, hasher = nil, metadata_version = nil)
      if metadata_version and metadata_version >= 9
        storage_hash = Crypto.xxhash_128(storage_module_name) + Crypto.xxhash_128(storage_function_name)

        params = [params] if params.class != ::Array
        params_key = params.join("")
        hasher = "xxhash_128" if hasher.nil?
        storage_hash += Crypto.send hasher, params_key.hex_to_bytes.bytes_to_utf8

        "0x#{storage_hash}"
      else
        # TODO: add test
        storage_hash = storage_module_name + " " + storage_function_name

        params = [params] if params.class != ::Array
        params_key = params.join("")
        hasher = "xxhash_128" if hasher.nil?
        storage_hash += params_key.hex_to_bytes.bytes_to_utf8 

        "0x#{Crypto.send( hasher, storage_hash )}"
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

