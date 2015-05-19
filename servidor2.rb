#!/usr/bin/env ruby1.9.1
require 'socket'               # Get sockets from stdlib
port = ARGV[0]

server = TCPServer.open(port)
loop {
#servidor com mais de um cliente
	Thread.start(server.accept) do |client|
	  puts "Mensagem recebida: #{client.recv(100)}"
	  client.send(Time.now.ctime,0)
	  client.send "Ending connection. Bye!",0
	  client.close                # Disconnect from the client
	end
}  