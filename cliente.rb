#!/usr/bin/env ruby1.9.1
# encoding: utf-8
require 'socket'
require "awesome_print"

#======================#
#        metodos       #
#======================#

def log(msg, val)
	case val
		when 0
			$file.puts msg
			puts msg
		when 1
			$file.puts msg
		when 2
			puts msg
		when 3
			$file.print msg
			print msg
		when 4
			print msg
		else			
			puts "Erro no logger"		
	end
end

def cabecalho
	log(" -----------------------------------------------------------------------",1)
	log("| Prof. Elias P. Duarte Jr.  -  Disciplina Redes 2                      |",1)
	log("| Trabalho que implementa a Consistência de Dados com 2PC Simplificado  |",1)
	log(" -----------------------------------------------------------------------",1)
	log("Cliente \n",1)
end

numServers=1
hostnames = []
portas = []
socket = []
filename = "cliente.txt"
$file = File.new(filename, "w+")
cabecalho
numServers.times do |i|
	log("Digite o nome do servidor #{i+1}: ",2)
	hostnames[i]=gets.chomp	# array com nome dos servidores
	log("Digite a porta do servidor #{i+1}: ",2)
	portas[i]=gets.chomp	# array com porta dos servidores
	log("Inserindo o servidor #{hostnames[i]} com #{portas[i]} para poder fazer conexão.",1)
end
opcao = 0
system "clear"
while opcao!=4
	log("Este cliente esta conectado aos seguintes servidores: ",0)
	numServers.times do |i|
		if i<numServers-1
			log("#{hostnames[i]}:#{portas[i]}, ",3)
		else
			log("#{hostnames[i]}:#{portas[i]}.",0)
		end
	end
	log("
	Escolha uma opção
	1 - Trocar palavra-chave.
	2 - Ver palavra-chave.
	3 - Ver arquivo.
	4 - Sair.
	? ", 3)

	opcao = gets.chomp.to_i
	log("opcao digitada #{opcao}",1)
	system("clear")
	case opcao
		when 1 # SETKEY
			okArray=[]
	
			numServers.times do |i|	# abre sockets
				socket[i] = TCPSocket.open(hostnames[i], portas[i].to_i)	# hash com chave="nome do host" e valor=TCPSocket
			end
	
			numServers.times do |i|
				log("",1)
				log("Enviando requisição para #{hostnames[i]}:#{portas[i]}...",0)
				socket[i].send("SETKEY",0)
				log("Requisição SETKEY enviada. Aguardando resposta...",0)
				resposta = socket[i].recv(100)
				if resposta == "OK"
					okArray << i
					log("#{hostnames[i]}:#{portas[i]} respondeu OK.",0)
				elsif resposta=="NOK"
					log("#{hostnames[i]}:#{portas[i]} está ocupado.",0)
				else
					log("Resposta recebida: '#{resposta}'.",0)
					log("Resposta inválida.",0)
				end
			end
			
			log("",1)	
			if okArray.size<numServers
				okArray.each do |i|
					log("Enviando ABORT para #{hostnames[i]}:#{portas[i]}...",0)
					socket[i].send("ABORT",0)
					log("ABORT enviado para #{hostnames[i]}:#{portas[i]}....",0)
				end
			else
				# enviar COMMIT com a alteração pra todo mundo.
				log("Digite a nova palavra-chave:",0)
				keyword = gets.chomp
				log("A palavra chave digita é: #{keyword}",0)
				numServers.times do |i|
	 				log("enviando um COMMIT para o #{socket[i]}",1)
					socket[i].send("COMMIT",0)
					confirmacao = socket[i].recv(100)
					log("recebendo a confirmação #{confirmacao} do #{socket[i]}",1)
					if confirmacao=="ACK"
						socket[i].send(keyword, 0)
						log("Palavra-chave '#{keyword}' enviada para o host #{hostnames[i]}:#{portas[i].to_i} com sucesso!",0)
					else
						log("Falha ao receber confirmação do servidor.",0)
						log("Mensagem do servidor: '#{confirmacao}'.",0)
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
				log("",1)
				log("Enviando requisição para #{hostnames[i]}:#{portas[i]}...",0)
				socket[i].send("GETKEY",0)
				log("Requisição GETKEY enviada. Aguardando resposta...",0)
				resposta = socket[i].recv(100)
				if resposta == "OK"
					okArray << i
					log("#{hostnames[i]}:#{portas[i]} respondeu OK.",0)
				elsif resposta=="NOK" 
					log("#{hostnames[i]}:#{portas[i]} está ocupado.",0)
				else
					log("Resposta recebida: '#{resposta}'.",0)
					log("Resposta inválida.",0)
				end
			end
	
			log("",1)
			if okArray.size<numServers
				okArray.each do |i|
					log("Enviando ABORT para #{hostnames[i]}:#{portas[i]}...",0)
					socket[i].send("ABORT",0)
					log("ABORT enviado para #{hostnames[i]}:#{portas[i]}....",0)
				end
			else
				# enviar COMMIT com a alteração pra todo mundo.
				log("",1)
				keyArray = []
				numServers.times do |i|
	 				log("enviando um COMMIT para o #{socket[i]}",1)
					socket[i].send("COMMIT",0)
					keyArray[i] = socket[i].recv(100)
					log("Palavra-chave recebida do host #{hostnames[i]}:#{portas[i].to_i} com sucesso! ",0)
				end
				if keyArray.uniq.length > 1
					log("Palavras-chave recebidas são diferentes.",0)
					numServers.times do |i|
						log("Palavra-chave recebida de #{hostnames[i]}:#{portas[i].to_i}:",0)
						log(keyArray[i],0)
						log("",0)
					end
				else
					log("Palavras-chave recebidas são iguais.",0)
					log("Palavra-chave: ",4)
					log(keyArray.first,0)
					log("",0)
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
				log("",1)
	 			log("Enviando requisição para #{hostnames[i]}:#{portas[i]}...",0)
				socket[i].send("GETFILE",0)
				log("Requisição GETFILE enviada. Aguardando resposta...",0)
				resposta = socket[i].recv(100)
				if resposta == "OK"
					okArray << i
					log("#{hostnames[i]}:#{portas[i]} respondeu OK.",0)
				elsif resposta=="NOK" 
					log("#{hostnames[i]}:#{portas[i]} está ocupado.",0)
				else
					log("Resposta recebida: '#{resposta}'.",0)
					log("Resposta inválida.",0)
				end
			end

			log("",1)
			if okArray.size<numServers
				okArray.each do |i|
					log("Enviando ABORT para #{hostnames[i]}:#{portas[i]}...",0)
					socket[i].send("ABORT",0)
					log("ABORT enviado para #{hostnames[i]}:#{portas[i]}....",0)
				end
			else
				# enviar COMMIT com a alteração pra todo mundo.
				arqArray = []
				numServers.times do |i|
					log("",1)
	 				log("enviando um COMMIT para o #{socket[i]}",1)
					socket[i].send("COMMIT",0)
					tamArq = socket[i].recv(100).to_i
					socket[i].send("ACK",0)
					arqArray[i] = socket[i].recv(tamArq)
					log("Arquivo de #{arqArray[i].size} bytes recebido do host #{hostnames[i]}:#{portas[i].to_i} com sucesso! ",0)
				end
				if arqArray.uniq.length > 1
					puts "Arquivos recebidos são diferentes."
					numServers.times do |i|
						log("Arquivo recebido de #{hostnames[i]}:#{portas[i].to_i}:",0)
						log("#{arqArray[i]}",0)
						log("",0)
					end
				else
					log("Arquivos recebidos são iguais.",0)
					log("Arquivo recebido:",0)
					log("#{arqArray.first}",0)
					log("",0)
				end
			end
			
			socket.each do |s|	# fecha sockets
				s.close
			end
		when 4			
		else # EXIT
			log("Opcao inválida",0)
	end

	log("",1)
end
log("Saindo do Cliente.",1)
$file.close


