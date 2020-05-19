require "faye/websocket"
require "eventmachine"

class SubstrateClient::Websocket
  HEARTBEAT_INTERVAL = 3
  RECONNECT_INTERVAL = 3

  def initialize(url, onopen: nil, onmessage: nil)
    @url = url
    @onopen = onopen || proc { p [:open] }
    @onmessage = onmessage || proc { |event| p [:message, event.data] }

    @thread = Thread.new do
      EM.run do
        start_connection
      end
      SubstrateClient.logger.info "Event loop stopped"
    end
    @heartbeat_thread = start_heartbeat
  end

  def start_connection
    SubstrateClient.logger.info "Start to connect"
    @close = false
    @missed_heartbeats = 0
    @ping_id = 0
    @ws = Faye::WebSocket::Client.new(@url)
    @ws.on :open do |event|
      @do_heartbeat = true
      @onopen.call event
    end

    @ws.on :message do |event|
      @onmessage.call event
    end

    @ws.on :close do |event|
      # p [:close, event.code, event.reason]
      if @close == false
        @do_heartbeat = false
        sleep RECONNECT_INTERVAL
        start_connection
      end
    end

  end

  def start_heartbeat
    Thread.new do
      loop do
        send_heartbeat if @do_heartbeat
        sleep HEARTBEAT_INTERVAL
      end
    end
  end

  def send_heartbeat
    if @missed_heartbeats < 2
      # puts "ping_#{@ping_id}"
      @ws.ping @ping_id.to_s do
        # puts "pong"
        @missed_heartbeats -= 1
      end
      @missed_heartbeats += 1
      @ping_id += 1
    end
  end

  def send(message)
    @ws.send message
  end

  def close
    @close = true
    Thread.kill @heartbeat_thread
    Thread.kill @thread
    @ws = nil
  end
end
