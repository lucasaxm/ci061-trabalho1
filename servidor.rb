#!/usr/bin/env ruby1.9.1
# encoding: utf-8

require 'socket'               # Get sockets from stdlib
require 'thread'
port = ARGV[0]
dado = ""
mutex = Mutex.new
clientId = 0
server = TCPServer.open(port)
loop {
#servidor com mais de um cliente
	Thread.start(server.accept) do |client|
		puts "Conexão estabelecida com o cliente #{clientId}"
		puts "Aguardando requisicao..."
		requisicao = client.recv(100)
		puts "Requisição recebida: #{requisicao}."
		if (requisicao == "EDIT") && mutex.locked?
			puts "Outro cliente está alterando o dado. Enviando NOK para cliente #{clientId}..."
			client.send("NOK",0)
			puts "NOK enviado para cliente #{clientId}."
		elsif (requisicao == "EDIT") && !mutex.locked?
			puts "Enviando OK para cliente #{clientId}..."
			client.send("OK",0)
			puts "OK enviado para cliente #{clientId}."
			puts "Aguardando nova requisição do cliente #{clientId}..."
			requisicao = client.recv(100)
			if requisicao == "COMMIT"
				mutex.synchronize do
					puts "Requisição recebida: #{requisicao}."
					dadoOld = dado
					dado = client.recv(100)
					puts "Dado alterado de #{dadoOld} para #{dado}."
				end	
			elsif requisicao == "ABORT"
				puts "Requisição recebida: #{requisicao}."
				puts "Operacao Cancelada"
			end									
 		else
 			puts "Resposta inválida."
 		end
		client.send("Fechando Conexão. Até mais!",0)
		client.close
	end
	clientId+=1
}  