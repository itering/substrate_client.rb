require "substrate_client/version"

require "substrate_common"
require "faye/websocket"
require "eventmachine"
require "json"

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

  # general api method
  def method_missing(method, *args)
    data = request(method, args)
    data["result"]
  end

  

  # hasher: 'xxhash_128', 'black2_256'
  def self.generate_storage_hash(storage_module_name, storage_function_name, params = nil, hasher = nil, metadata_version = nil)
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

end

