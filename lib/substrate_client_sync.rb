def ws_request(url, payload)
  queue = TimeoutQueue.new

  thread = Thread.new do
    EM.run do
      ws = Faye::WebSocket::Client.new(url)

      ws.on :open do |event|
        ws.send(payload.to_json)
      end

      ws.on :message do |event|
        if event.data.include?("jsonrpc")
          queue << JSON.parse(event.data)
          ws.close(3001, "data received")
          Thread.kill thread
        end
      end

      ws.on :close do |event|
        ws = nil
      end
    end
  end

  queue.pop true, 10
rescue ThreadError => ex
  raise SubstrateClientSync::RpcTimeout
end

class SubstrateClientSync
  class RpcError < StandardError; end
  class RpcTimeout < StandardError; end

  attr_accessor :spec_name, :spec_version, :metadata

  def initialize(url, spec_name: nil)
    @url = url
    @request_id = 1
    @spec_name = spec_name
    Scale::TypeRegistry.instance.load(spec_name)
  end

  def request(method, params)
    payload = {
      "jsonrpc" => "2.0",
      "method" => method,
      "params" => params,
      "id" => @request_id
    }

    data = ws_request(@url, payload)
    if data["error"]
      raise RpcError, data["error"]
    else
      data["result"]
    end
  end

  def init_runtime(block_hash=nil)
    # set current runtime spec version
    runtime_version = self.state_get_runtime_version(block_hash)
    @spec_version = runtime_version["specVersion"]
    Scale::TypeRegistry.instance.spec_version = @spec_version

    # set current metadata
    @metadata = self.get_metadata(block_hash)
    Scale::TypeRegistry.instance.metadata = @metadata.value
    true
  end

  def invoke(method, *params)
    # params.reject! { |param| param.nil? }
    request(method, params)
  end

  def rpc_method(method_name)
    SubstrateClient::Helper.real_method_name(method_name.to_s)
  end

  # ################################################
  # origin rpc methods
  # ################################################
  def method_missing(method, *args)
    rpc_method = SubstrateClient::Helper.real_method_name(method)
    invoke rpc_method, *args
  end

  def state_get_runtime_version(block_hash=nil)
    invoke rpc_method(__method__), block_hash
  end

  def rpc_methods 
    invoke rpc_method(__method__)
  end

  def chain_get_head
    invoke rpc_method(__method__)
  end

  def chain_get_finalised_head
    invoke rpc_method(__method__)
  end

  def chain_get_header(block_hash = nil)
    invoke rpc_method(__method__), block_hash
  end

  def chain_get_block(block_hash = nil)
    invoke rpc_method(__method__), block_hash
  end

  def chain_get_block_hash(block_id)
    invoke rpc_method(__method__), block_id
  end

  def chain_get_runtime_version(block_hash = nil)
    invoke rpc_method(__method__), block_hash
  end

  def state_get_metadata(block_hash = nil)
    invoke rpc_method(__method__), block_hash
  end

  def state_get_storage(storage_key, block_hash = nil)
    invoke rpc_method(__method__), storage_key, block_hash
  end

  def system_name
    invoke rpc_method(__method__)
  end

  def system_version
    invoke rpc_method(__method__)
  end

  # ################################################
  # custom methods based on origin rpc methods
  # ################################################
  def method_list
    self.rpc_methods["methods"].map(&:underscore)
  end

  def get_block_number(block_hash)
    header = self.chain_get_header(block_hash)
    header["number"].to_i(16)
  end

  def get_metadata(block_hash=nil)
    hex = self.state_get_metadata(block_hash)
    Scale::Types::Metadata.decode(Scale::Bytes.new(hex))
  end

  def get_block(block_hash=nil)
    self.init_runtime(block_hash)
    block = self.chain_get_block(block_hash)
    SubstrateClient::Helper.decode_block(block)
  end

  def get_block_events(block_hash=nil)
    self.init_runtime(block_hash)

    storage_key =  "0x26aa394eea5630e07c48ae0c9558cef780d41e5e16056765bc8461851072c9d7"
    events_data = state_get_storage storage_key, block_hash

    scale_bytes = Scale::Bytes.new(events_data)
    Scale::Types.get("Vec<EventRecord>").decode(scale_bytes).to_human
  end

  # Plain: client.get_storage("Sudo", "Key")
  # Plain: client.get_storage("Balances", "TotalIssuance")
  # Map: client.get_storage("System", "Account", ["0xd43593c715fdd31c61141abd04a99fd6822c8558854ccde39a5684e7a56da27d"])
  # DoubleMap: client.get_storage("ImOnline", "AuthoredBlocks", [2818, "0x749ddc93a65dfec3af27cc7478212cb7d4b0c0357fef35a0163966ab5333b757"])
  def get_storage(module_name, storage_name, params = nil, block_hash = nil)
    self.init_runtime(block_hash)

    storage_hash, return_type = SubstrateClient::Helper.generate_storage_hash_from_metadata(@metadata, module_name, storage_name, params)

    result = self.state_get_storage(storage_hash, block_hash)
    return unless result
    Scale::Types.get(return_type).decode(Scale::Bytes.new(result))
  end

  # compose_call "Balances", "Transfer", { dest: "0x586cb27c291c813ce74e86a60dad270609abf2fc8bee107e44a80ac00225c409", value: 1_000_000_000_000 }
  def compose_call(module_name, call_name, params, block_hash=nil)
    self.init_runtime(block_hash)
    SubstrateClient::Helper.compose_call_from_metadata(@metadata, module_name, call_name, params)
  end

end
