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
filename = "servidor#{port}.txt"
file = File.new(filename, "w+")
file.puts " -----------------------------------------------------------------------"
file.puts "| Prof. Elias P. Duarte Jr.  -  Disciplina Redes 2                      |"
file.puts "| Trabalho que implementa a Consistência de Dados com 2PC Simplificado  |"
file.puts " -----------------------------------------------------------------------"
file.puts "Servidor: #{port}"
loop {
#servidor com mais de um cliente
	Thread.start(server.accept) do |client|
		clientId = contClient
		file.puts "\n"
		ap "\n"
		file.puts "Thread #{Thread.current.object_id}: Conexão estabelecida com o cliente #{clientId}"
		file.puts "Thread #{Thread.current.object_id}: Aguardando requisicao..."
		ap "Thread #{Thread.current.object_id}: Conexão estabelecida com o cliente #{clientId}"
		ap "Thread #{Thread.current.object_id}: Aguardando requisicao..."
		requisicao = client.recv(100)
		file.puts "Thread #{Thread.current.object_id}: Requisição recebida: '#{requisicao}'."
		ap "Thread #{Thread.current.object_id}: Requisição recebida: '#{requisicao}'."
		if (requisicao == "EDIT")
			if !mutex.try_lock
				file.puts "Thread #{Thread.current.object_id}: Outro cliente está alterando o dado. Enviando NOK para cliente #{clientId}..."
				ap "Thread #{Thread.current.object_id}: Outro cliente está alterando o dado. Enviando NOK para cliente #{clientId}..."
				client.send("NOK",0)
				file.puts "Thread #{Thread.current.object_id}: NOK enviado para cliente #{clientId}."
				ap "Thread #{Thread.current.object_id}: NOK enviado para cliente #{clientId}."
			else
				file.puts "Thread #{Thread.current.object_id}: Enviando OK para cliente #{clientId}..."
				ap "Thread #{Thread.current.object_id}: Enviando OK para cliente #{clientId}..."
				client.send("OK",0)
				file.puts "Thread #{Thread.current.object_id}: OK enviado para cliente #{clientId}."
				file.puts "Thread #{Thread.current.object_id}: Aguardando nova requisição do cliente #{clientId}..."
				ap "Thread #{Thread.current.object_id}: OK enviado para cliente #{clientId}."
				ap "Thread #{Thread.current.object_id}: Aguardando nova requisição do cliente #{clientId}..."
				requisicao = client.recv(100)
				if requisicao == "COMMIT"
					# mutex.synchronize do
					client.send("ACK",0)
					file.puts "Thread #{Thread.current.object_id}: Requisição recebida: '#{requisicao}'."
					ap "Thread #{Thread.current.object_id}: Requisição recebida: '#{requisicao}'."
					dadoOld = dado
					dado = client.recv(100)
					# file.puts "Thread #{Thread.current.object_id}: sleeping 10sec."
					# puts "Thread #{Thread.current.object_id}: sleeping 10sec."
					# sleep 10
					# file.puts "Thread #{Thread.current.object_id}: wake!"
					# puts "Thread #{Thread.current.object_id}: wake!"
					file.puts "Thread #{Thread.current.object_id}: Dado alterado de '#{dadoOld}' para '#{dado}'."
					ap "Thread #{Thread.current.object_id}: Dado alterado de '#{dadoOld}' para '#{dado}'."
					# end	
				elsif requisicao == "ABORT"
					file.puts "Thread #{Thread.current.object_id}: Requisição recebida '#{requisicao}'."
					file.puts "Thread #{Thread.current.object_id}: Operacao Cancelada"
					ap "Thread #{Thread.current.object_id}: Requisição recebida '#{requisicao}'."
					ap "Thread #{Thread.current.object_id}: Operacao Cancelada"
				else
					file.puts "Thread #{Thread.current.object_id}: Requisição recebida: '#{requisicao}'."
					file.puts "Thread #{Thread.current.object_id}: Resposta inválida"
					file.puts "Thread #{Thread.current.object_id}: Resposta esperada: COMMIT ou ABORT." 
					ap "Thread #{Thread.current.object_id}: Requisição recebida: '#{requisicao}'."
					ap "Thread #{Thread.current.object_id}: Resposta inválida"
					ap "Thread #{Thread.current.object_id}: Resposta esperada: COMMIT ou ABORT."
				end
				mutex.unlock
			end										
 		else
 			file.puts "Thread #{Thread.current.object_id}: Resposta inválida."
			file.puts "Thread #{Thread.current.object_id}: (Resposta esperada: EDIT.)"
 			ap "Thread #{Thread.current.object_id}: Resposta inválida."
			ap "Thread #{Thread.current.object_id}: (Resposta esperada: EDIT.)"
 		end

 		file.puts "Thread #{Thread.current.object_id}: Fechando Conexão com o cliente #{clientId}." 
 		ap "Thread #{Thread.current.object_id}: Fechando Conexão com o cliente #{clientId}." 		
		client.close
	end
		contClient+=1
}
file.close