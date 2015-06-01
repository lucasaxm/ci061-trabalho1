#!/usr/bin/env ruby1.9.1
# encoding: utf-8
require 'socket'
require "awesome_print"

#======================#
#        metodos       #
#======================#

def log(file, msg, val)
	case val
		when 0
			file.puts msg
			puts msg
		when 1
			file.puts msg
		when 2
			puts msg
		when 3
			file.print msg
			print msg
		when 4
			print msg
		else			
			puts "Erro no logger"		
	end
end

def cabecalho(file)
	log(file, " -----------------------------------------------------------------------",1)
	log(file, "| Prof. Elias P. Duarte Jr.  -  Disciplina Redes 2                      |",1)
	log(file, "| Trabalho que implementa a Consistência de Dados com 2PC Simplificado  |",1)
	log(file, " -----------------------------------------------------------------------",1)
	log(file, "Cliente \n",1)
end

numServers=2
hostnames = []
portas = []
socket = []
filename = "cliente.txt"
file = File.new(filename, "w+")
cabecalho(file)
numServers.times do |i|
	log(file, "Digite o nome do servidor #{i}: ",2)
	hostnames[i]=gets.chomp	# array com nome dos servidores
	log(file, "Digite a porta do servidor #{i}: ",2)
	portas[i]=gets.chomp	# array com porta dos servidores
	log(file, "Inserindo o servidor #{hostnames[i]} com #{portas[i]} para poder fazer conexão.",1)
end
opcao = 0
system "clear"
while opcao!=4
	log(file,"Este cliente esta conectado aos seguintes servidores: ",0)
	numServers.times do |i|
		if i<numServers-1
			log(file, "#{hostnames[i]}:#{portas[i]}, ",3)
		else
			log(file, "#{hostnames[i]}:#{portas[i]}.",0)
		end
	end
	log(file, "
	Escolha uma opção
	1 - Trocar palavra-chave.
	2 - Ver palavra-chave.
	3 - Ver arquivo.
	4 - Sair.
	? ", 3)

	opcao = gets.chomp.to_i
	log(file,"opcao digitada #{opcao}",1)

	case opcao
		when 1 # SETKEY
			okArray=[]
	
			numServers.times do |i|	# abre sockets
				socket[i] = TCPSocket.open(hostnames[i], portas[i].to_i)	# hash com chave="nome do host" e valor=TCPSocket
			end
	
			numServers.times do |i|
				log(file, "",1)
				log(file, "Enviando requisição para #{hostnames[i]}:#{portas[i]}...",0)
				socket[i].send("SETKEY",0)
				log(file, "Requisição SETKEY enviada. Aguardando resposta...",0)
				resposta = socket[i].recv(100)
				if resposta == "OK"
					okArray << i
					log(file,"#{hostnames[i]}:#{portas[i]} respondeu OK.",0)
				elsif resposta=="NOK"
					log(file, "#{hostnames[i]}:#{portas[i]} está ocupado.",0)
				else
					log(file,"Resposta recebida: '#{resposta}'.",0)
					log(file,"Resposta inválida.",0)
				end
			end
			
			log(file, "",1)	
			if okArray.size<numServers
				okArray.each do |i|
					log(file, "Enviando ABORT para #{hostnames[i]}:#{portas[i]}...",0)
					socket[i].send("ABORT",0)
					log(file, "ABORT enviado para #{hostnames[i]}:#{portas[i]}....",0)
				end
			else
				# enviar COMMIT com a alteração pra todo mundo.
				log(file, "Digite a nova palavra-chave:",0)
				keyword = gets.chomp
				log(file, "A palavra chave digita é: #{keyword}",0)
				numServers.times do |i|
	 				log(file, "enviando um COMMIT para o #{socket[i]}",1)
					socket[i].send("COMMIT",0)
					confirmacao = socket[i].recv(100)
					log(file, "recebendo a confirmação #{confirmacao} do #{socket[i]}",1)
					if confirmacao=="ACK"
						socket[i].send(keyword, 0)
						log(file, "Palavra-chave '#{keyword}' enviada para o host #{hostnames[i]}:#{portas[i].to_i} com sucesso!",0)
					else
						log(file, "Falha ao receber confirmação do servidor.",0)
						log(file, "Mensagem do servidor: '#{confirmacao}'.",0)
					end					
				end
			end
			
			socket.each do |s|	# fecha sockets
				s.close
			end
		when 2 # GETKEY
			okArray=[]
	
			numServers.times do |i|	# abre sockets
				socket[i] = TCPSocket.open(hostnames[i], portas[i].to_i)	# hash com chave="nome do host" e valor=TCPSocket
			end
	
			numServers.times do |i| # envia GETFILE
				log(file, "",1)
				log(file,"Enviando requisição para #{hostnames[i]}:#{portas[i]}...",0)
				socket[i].send("GETKEY",0)
				log(file,"Requisição GETKEY enviada. Aguardando resposta...",0)
				resposta = socket[i].recv(100)
				if resposta == "OK"
					okArray << i
					log(file, "#{hostnames[i]}:#{portas[i]} respondeu OK.",0)
				elsif resposta=="NOK" 
					log(file, "#{hostnames[i]}:#{portas[i]} está ocupado.",0)
				else
					log(file, "Resposta recebida: '#{resposta}'.",0)
					log(file, "Resposta inválida.",0)
				end
			end
	
			log(file, "",1)
			if okArray.size<numServers
				okArray.each do |i|
					log(file,"Enviando ABORT para #{hostnames[i]}:#{portas[i]}...",0)
					socket[i].send("ABORT",0)
					log(file,"ABORT enviado para #{hostnames[i]}:#{portas[i]}....",0)
				end
			else
				# enviar COMMIT com a alteração pra todo mundo.
				log(file, "",1)
				keyArray = []
				numServers.times do |i|
	 				log(file, "enviando um COMMIT para o #{socket[i]}",1)
					socket[i].send("COMMIT",0)
					keyArray[i] = socket[i].recv(100)
					log(file, "Palavra-chave recebida do host #{hostnames[i]}:#{portas[i].to_i} com sucesso! ",0)
				end
				if keyArray.uniq.length > 1
					log(file, "Palavras-chave recebidas são diferentes.",0)
					numServers.times do |i|
						log(file, "Palavra-chave recebida de #{hostnames[i]}:#{portas[i].to_i}:",0)
						log(file, keyArray[i],0)
						log(file, "",0)
					end
				else
					log(file, "Palavras-chave recebidas são iguais.",0)
					log(file, "Palavra-chave: ",4)
					log(file, keyArray.first,0)
					log(file, "",0)
				end
			end
			
			socket.each do |s|	# fecha sockets
				s.close
			end		
		when 3 # GETFILE
			okArray=[]
	
			numServers.times do |i|	# abre sockets
				socket[i] = TCPSocket.open(hostnames[i], portas[i].to_i)	# hash com chave="nome do host" e valor=TCPSocket
			end
	
			numServers.times do |i| # envia GETFILE
				log(file, "",1)
	 			log(file, "Enviando requisição para #{hostnames[i]}:#{portas[i]}...",0)
				socket[i].send("GETFILE",0)
				log(file, "Requisição GETFILE enviada. Aguardando resposta...",0)
				resposta = socket[i].recv(100)
				if resposta == "OK"
					okArray << i
					log(file, "#{hostnames[i]}:#{portas[i]} respondeu OK.",0)
				elsif resposta=="NOK" 
					log(file, "#{hostnames[i]}:#{portas[i]} está ocupado.",0)
				else
					log(file, "Resposta recebida: '#{resposta}'.",0)
					log(file, "Resposta inválida.",0)
				end
			end

			log(file, "",1)
			if okArray.size<numServers
				okArray.each do |i|
					log(file, "Enviando ABORT para #{hostnames[i]}:#{portas[i]}...",0)
					socket[i].send("ABORT",0)
					log(file, "ABORT enviado para #{hostnames[i]}:#{portas[i]}....",0)
				end
			else
				# enviar COMMIT com a alteração pra todo mundo.
				arqArray = []
				numServers.times do |i|
					log(file, "",1)
	 				log(file, "enviando um COMMIT para o #{socket[i]}",1)
					socket[i].send("COMMIT",0)
					tamArq = socket[i].recv(100).to_i
					socket[i].send("ACK",0)
					arqArray[i] = socket[i].recv(tamArq)
					log(file, "Arquivo de #{arqArray[i].size} bytes recebido do host #{hostnames[i]}:#{portas[i].to_i} com sucesso! ",0)
				end
				if arqArray.uniq.length > 1
					puts "Arquivos recebidos são diferentes."
					numServers.times do |i|
						log(file, "Arquivo recebido de #{hostnames[i]}:#{portas[i].to_i}:",0)
						log(file, "#{arqArray[i]}",0)
						log(file, "",0)
					end
				else
					log(file, "Arquivos recebidos são iguais.",0)
					log(file, "Arquivo recebido:",0)
					log(file, "#{arqArray.first}",0)
					log(file, "",0)
				end
			end
			
			socket.each do |s|	# fecha sockets
				s.close
			end
		when 4			
		else # EXIT
			log(file, "Opcao inválida",0)
	end

	log(file, "",1)
end
log(file, "Saindo do Cliente.",1)
file.close


