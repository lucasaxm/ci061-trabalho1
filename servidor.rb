#!/usr/bin/env ruby1.9.1
# encoding: utf-8

require 'socket'               # Get sockets from stdlib
require 'thread'
require 'awesome_print'
port = ARGV[0]
dado = "My precious Taz and Toph"
mutex = Mutex.new
contClient = 0
server = TCPServer.open(port)
loop {
#servidor com mais de um cliente
	Thread.start(server.accept) do |client|
		clientId = contClient
		ap "Thread #{Thread.current.object_id}: Conexão estabelecida com o cliente #{clientId}"
		ap "Thread #{Thread.current.object_id}: Aguardando requisicao..."
		requisicao = client.recv(100)
		ap "Thread #{Thread.current.object_id}: Requisição recebida: '#{requisicao}'."
		if (requisicao == "EDIT")
			if !mutex.try_lock
				ap "Thread #{Thread.current.object_id}: Outro cliente está alterando o dado. Enviando NOK para cliente #{clientId}..."
				client.send("NOK",0)
				ap "Thread #{Thread.current.object_id}: NOK enviado para cliente #{clientId}."
			else
				ap "Thread #{Thread.current.object_id}: Enviando OK para cliente #{clientId}..."
				client.send("OK",0)
				ap "Thread #{Thread.current.object_id}: OK enviado para cliente #{clientId}."
				ap "Thread #{Thread.current.object_id}: Aguardando nova requisição do cliente #{clientId}..."
				requisicao = client.recv(100)
				if requisicao == "COMMIT"
					# mutex.synchronize do
					client.send("ACK",0)
						ap "Thread #{Thread.current.object_id}: Requisição recebida: '#{requisicao}'."
						dadoOld = dado
						dado = client.recv(100)
						ap "Thread #{Thread.current.object_id}: Dado alterado de '#{dadoOld}' para '#{dado}'."
					# end	
				elsif requisicao == "ABORT"
					ap "Thread #{Thread.current.object_id}: Requisição recebida '#{requisicao}'."
					ap "Thread #{Thread.current.object_id}: Operacao Cancelada"
				else 
					ap "Thread #{Thread.current.object_id}: Requisição recebida: '#{requisicao}'."
					ap "Thread #{Thread.current.object_id}: Resposta inválida"
					ap "Thread #{Thread.current.object_id}: Resposta esperada: COMMIT ou ABORT."
				end
				mutex.unlock
			end										
 		else
 			ap "Thread #{Thread.current.object_id}: Resposta inválida."
			ap "Thread #{Thread.current.object_id}: (Resposta esperada: EDIT.)"
 		end 
 		ap "Thread #{Thread.current.object_id}: Fechando Conexão com o cliente #{clientId}." 
		
		client.close
	end
		contClient+=1
}  