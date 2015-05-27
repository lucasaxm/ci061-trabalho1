#!/usr/bin/env ruby1.9.1
require 'socket'               # Get sockets from stdlib
require 'thread'
port = ARGV[0]

mutex = Mutex.new

server = TCPServer.open(port)
loop {
#servidor com mais de um cliente
	Thread.start(server.accept) do |client|
		  puts "Recebendo uma requisicao: #{client.recv(100)}"
		  requisicao = client.recv(100)
		  if (requisicao == "EDIT") && mutex.locked?
		  	client.send("NOK",0)
		  elsif (requisicao == "EDIT") && !mutex.locked?
			client.send("OK",0)
			requisicao = client.recv(100)
			if requisicao == "COMMIT"
			  mutex.synchronize do
				  #faz a mudança do dado
				  # Disconnect from the client

			  end	
			elsif requisicao == "ABORT"
				puts "Operacao Cancelada"
			end						  			
		  client.send ("Fechando Conexão. Até mais!",0)
		  client.close          
		  end
	end
}  