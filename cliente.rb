#!/usr/bin/env ruby1.9.1
# encoding: utf-8

require 'socket'
hostnames = []
portas = []
socket = []
3.times do |i|
	puts "Digite o nome do servidor #{i}: "
	hostnames[i]=gets.chomp	# array com nome dos servidores
	puts "Digite a porta do servidor #{i}: "
	portas[i]=gets.chomp	# array com porta dos servidores
	socket[hostnames[i]] = TCPSocket.open(hostnames[i], portas[i])	# hash com chave="nome do host" e valor=TCPSocket
end
opcao = 0
while opcao!=2
	print "
	Escolha uma opção
	1 - Editar arquivo no servidor.
	2 - Sair.
	? "
	opcao = gets.chomp.to_i

	if opcao==1
		okArray=[]
	 	hostnames.each do |host|
	 		puts "Enviando requisição para #{host}"
	 		socket[host].send("EDIT",0)
	 		resposta = socket[host].recv(100)
	 		if resposta == "OK"
	 			okArray << host
	 			puts "#{host} respondeu OK."
	 		elsif resposta=="NOK" 
	 			puts "#{host} esta ocupado."
	 			okArray.each { |okHost|
	 				socket[host].send("ABORT",0)
	 				puts "ABORT enviado para #{okHost}."
	 			}
	 			break
	 		end
	 	end
	 	if okArray.size == hostnames.size
	 		# enviar COMMIT com a alteração pra todo mundo.
	 		puts "Digite o novo valor do dado:"
	 		dado = gets.chomp
	 		hostnames.each do |host|
	 			socket[host].send("COMMIT",0)
 				socket[host].send(dado, 0)
 				puts "String '#{}' enviada para o host #{host} com sucesso!"
	 		end
	 	end
	end
end

s.send(texto,0)
puts s.recv(100)

s.close               # Close the socket when done