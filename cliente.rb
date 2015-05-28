#!/usr/bin/env ruby1.9.1
# encoding: utf-8

require 'socket'
numServers=3
hostnames = []
portas = []
socket = {}
numServers.times do |i|
	puts "Digite o nome do servidor #{i}: "
	hostnames[i]=gets.chomp	# array com nome dos servidores
	puts "Digite a porta do servidor #{i}: "
	portas[i]=gets.chomp	# array com porta dos servidores
	socket[hostnames[i]] = TCPSocket.open(hostnames[i], portas[i].to_i)	# hash com chave="nome do host" e valor=TCPSocket
end
opcao = 0
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
	 	hostnames.each_with_index do |host, i|
	 		puts "Enviando requisição para #{host}:#{portas[i].to_i}..."
	 		socket[host].send("EDIT",0)
	 		puts "Requisição EDIT enviada. Aguardando resposta..."
	 		resposta = socket[host].recv(100)
	 		if resposta == "OK"
	 			okArray << host
	 			puts "#{host}:#{portas[i].to_i} respondeu OK."
	 		elsif resposta=="NOK" 
	 			puts "#{host}:#{portas[i].to_i} esta ocupado."
	 			okArray.each { |okHost|
	 				puts "Enviando ABORT para #{okHost}"
	 				socket[host].send("ABORT",0)
	 				puts "ABORT enviado para #{okHost}."
	 			}
	 			break
	 		else
	 			puts "Resposta inválida."
	 		end
	 	end
	 	if okArray.size == hostnames.size
	 		# enviar COMMIT com a alteração pra todo mundo.
	 		puts "Digite o novo valor do dado:"
	 		dado = gets.chomp
	 		hostnames.each_with_index do |host, i|
	 			socket[host].send("COMMIT",0)
 				socket[host].send(dado, 0)
 				puts "String '#{dado}' enviada para o host #{host}:#{portas[i].to_i} com sucesso!"
	 		end
	 	end
	end
end

s.send(texto,0)
puts s.recv(100)

s.close               # Close the socket when done