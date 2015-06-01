#!/usr/bin/env ruby1.9.1
# encoding: utf-8
require 'socket'
require "awesome_print"

numServers=3
hostnames = []
portas = []
socket = []
filename = "cliente.txt"
file = File.new(filename, "w+")
file.puts " -----------------------------------------------------------------------"
file.puts "| Prof. Elias P. Duarte Jr.  -  Disciplina Redes 2                      |"
file.puts "| Trabalho que implementa a Consistência de Dados com 2PC Simplificado  |"
file.puts " -----------------------------------------------------------------------"
file.puts "Cliente \n"
numServers.times do |i|
	puts "Digite o nome do servidor #{i}: "
	hostnames[i]=gets.chomp	# array com nome dos servidores
	puts "Digite a porta do servidor #{i}: "
	portas[i]=gets.chomp	# array com porta dos servidores
	file.puts "Inserindo o servidor #{hostnames[i]} com #{porta[i]} para poder fazer conexão."
end
opcao = 0
system "clear"
while opcao!=2
	file.puts "Este cliente esta conectado aos seguintes servidores: "
	print "Este cliente esta conectado aos seguintes servidores: "
	numServers.times do |i|
		if i!=2
			file.print "#{hostnames[i]}:#{portas[i]}, "
			print "#{hostnames[i]}:#{portas[i]}, "
		else
			file.puts "#{hostnames[i]}:#{portas[i]}."
			puts "#{hostnames[i]}:#{portas[i]}."
		end
	end
	file.puts"
	Escolha uma opção
	1 - Editar arquivo no servidor.
	2 - Sair.
	? "

	print "
	Escolha uma opção
	1 - Editar arquivo no servidor.
	2 - Sair.
	? "
	opcao = gets.chomp.to_i
	file.puts "opcao digitada #{opcao}"
	if opcao==1
		okArray=[]

		numServers.times do |i|	# abre sockets
			socket[i] = TCPSocket.open(hostnames[i], portas[i].to_i)	# hash com chave="nome do host" e valor=TCPSocket
		end

	 	numServers.times do |i|
	 		file.puts "\n"
	 		file.puts "Enviando requisição para #{hostnames[i]}:#{portas[i]}..."
	 		puts "Enviando requisição para #{hostnames[i]}:#{portas[i]}..."
	 		socket[i].send("EDIT",0)
	 		file.puts "Requisição EDIT enviada. Aguardando resposta..."
	 		puts "Requisição EDIT enviada. Aguardando resposta..."
	 		resposta = socket[i].recv(100)
	 		if resposta == "OK"
	 			okArray << i
	 			file.puts "#{hostnames[i]}:#{portas[i]} respondeu OK."
	 			puts "#{hostnames[i]}:#{portas[i]} respondeu OK."
	 		elsif resposta=="NOK" 
	 			file.puts "#{hostnames[i]}:#{portas[i]} está ocupado."
	 			puts "#{hostnames[i]}:#{portas[i]} está ocupado."
	 		else
	 			file.puts "Resposta recebida: '#{resposta}'."
	 			file.puts "Resposta inválida."
	 			puts "Resposta recebida: '#{resposta}'."
	 			puts "Resposta inválida."
	 		end
	 	end

	 	file.puts "\n"
 		if okArray.size<numServers
 			okArray.each do |i|
 				file.puts "Enviando ABORT para #{hostnames[i]}:#{portas[i]}..."
 				puts "Enviando ABORT para #{hostnames[i]}:#{portas[i]}..."
 				socket[i].send("ABORT",0)
 				file.puts "ABORT enviado para #{hostnames[i]}:#{portas[i]}...."
 				puts "ABORT enviado para #{hostnames[i]}:#{portas[i]}...."
 			end
 		else
	 		# enviar COMMIT com a alteração pra todo mundo.
	 		puts "Digite o novo valor do dado:"
	 		file.puts "Digite o novo valor do dado:"
	 		dado = gets.chomp
	 		file.puts "O dado digitado é: #{dado}"
	 		numServers.times do |i|
	 			file.puts "\n"
	 			file.puts "enviando um COMMIT para o #{socket[i]}"
	 			socket[i].send("COMMIT",0)
	 			confirmacao = socket[i].recv(100)
	 			file.puts "recebendo a confirmação #{confirmacao} do #{socket[i]}"
	 			if confirmacao=="ACK"
	 				socket[i].send(dado, 0)
	 				file.puts "String '#{dado}' enviada para o host #{hostnames[i]}:#{portas[i].to_i} com sucesso!"
	 				puts "String '#{dado}' enviada para o host #{hostnames[i]}:#{portas[i].to_i} com sucesso!"
	 			else
	 				file.puts "Falha ao receber confirmação do servidor."
	 				file.puts "Mensagem do servidor: '#{confirmacao}'."
	 				puts "Falha ao receber confirmação do servidor."
	 				puts "Mensagem do servidor: '#{confirmacao}'."
	 			end
	 			
	 		end
	 	end
		socket.each do |s|	# fecha sockets
			s.close
		end
	end
 	file.puts "\n"
 	file.puts "Saindo do Cliente."
end