#!/usr/bin/env ruby1.9.1
# encoding: utf-8
require 'socket'
require "awesome_print"

numServers=2
hostnames = []
portas = []
socket = []
numServers.times do |i|
	puts "Digite o nome do servidor #{i}: "
	hostnames[i]=gets.chomp	# array com nome dos servidores
	puts "Digite a porta do servidor #{i}: "
	portas[i]=gets.chomp	# array com porta dos servidores
end
opcao = 0
system "clear"
while opcao!=2
	print "Servidores: "
	numServers.times do |i|
		if i!=2
			print "#{hostnames[i]}:#{portas[i]}, "
		else
			puts "#{hostnames[i]}:#{portas[i]}."
		end
	end
	print "
	Escolha uma opção
	1 - Editar arquivo no servidor.
	2 - Sair.
	? "
	opcao = gets.chomp.to_i

	if opcao==1
		okArray=[]
		numServers.times do |i|	# abre sockets
			socket[i] = TCPSocket.open(hostnames[i], portas[i].to_i)	# hash com chave="nome do host" e valor=TCPSocket
		end
	 	numServers.times do |i|
	 		puts "Enviando requisição para #{hostnames[i]}:#{portas[i]}..."
	 		socket[i].send("EDIT",0)
	 		puts "Requisição EDIT enviada. Aguardando resposta..."
	 		resposta = socket[i].recv(100)
	 		if resposta == "OK"
	 			okArray << hostnames[i]
	 			puts "#{hostnames[i]}:#{portas[i]} respondeu OK."
	 		elsif resposta=="NOK" 
	 			puts "#{hostnames[i]}:#{portas[i]} está ocupado."
	 			okArray.each do |okHost|
	 				puts "Enviando ABORT para #{okHost}"
	 				socket[i].send("ABORT",0)
	 				puts "ABORT enviado para #{okHost}."
	 			end
	 			break
	 		else
	 			puts "Resposta recebida: '#{resposta}'."
	 			puts "Resposta inválida."
	 		end
	 	end
	 	if okArray.size == hostnames.size
	 		# enviar COMMIT com a alteração pra todo mundo.
	 		puts "Digite o novo valor do dado:"
	 		dado = gets.chomp
	 		numServers.times do |i|
	 			socket[i].send("COMMIT",0)
	 			confirmacao = socket[i].recv(100)
	 			if confirmacao=="ACK"
	 				socket[i].send(dado, 0)
	 				puts "String '#{dado}' enviada para o host #{hostnames[i]}:#{portas[i].to_i} com sucesso!"
	 			else
	 				puts "Falha ao receber confirmação do servidor."
	 				puts "Mensagem do servidor: '#{confirmacao}'."
	 			end
	 			
	 		end
	 	end
		socket.each do |s|	# fecha sockets
			s.close
		end
	end
end