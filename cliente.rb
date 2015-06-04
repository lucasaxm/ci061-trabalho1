#!/usr/bin/env ruby1.9.1
# encoding: utf-8
$LOAD_PATH << '.'
require 'socket'
require "awesome_print"
require "log"

numServers=1
$hostnames = []
$portas = []
$socket = []
# METODOS
def getServidores(numServers)
	numServers.times do |i|
		puts "Digite o nome do servidor #{i+1}: "
		$hostnames[i]=gets.chomp	# array com nome dos servidores
		puts "Digite a porta do servidor #{i+1}: "
		$portas[i]=gets.chomp	# array com porta dos servidores
		$log.report("Inserindo o servidor #{$hostnames[i]} na porta #{$portas[i]} para poder fazer conexão.",0)
	end
end	

def printServersConect(numServers)
	$log.report("Este cliente esta conectado aos seguintes servidores: \n",1)
	numServers.times do |i|
		if i<numServers-1
			$log.report("#{$hostnames[i]}:#{$portas[i]}, ",1)
		else
			$log.report("#{$hostnames[i]}:#{$portas[i]}.\n",1)
		end
	end	
end

def openSocket(numServers)
	numServers.times do |i|	# abre sockets
		$socket[i] = TCPSocket.open($hostnames[i], $portas[i].to_i)	# hash com chave="nome do host" e valor=TCPSocket
	end
end

def closeSocket
	$socket.each do |s|	# fecha sockets
		s.close
	end	
end

def requestOkOrNok(resposta, i)
	okArray = []
	if resposta == "OK"
		okArray << i
		$log.report("#{$hostnames[i]}:#{$portas[i]} respondeu OK.\n",1)
	elsif resposta=="NOK"
		$log.report("#{$hostnames[i]}:#{$portas[i]} está ocupado.\n",1)
	else
		$log.report("Resposta recebida: '#{resposta}'.\n",1)
		$log.report("Resposta inválida.\n",1)
	end
	return okArray	
end

def sendAbort(okArray)
	okArray.each do |i|
		$log.report("Enviando ABORT para #{$hostnames[i]}:#{$portas[i]}...\n",1)
		$socket[i].send("ABORT",0)
		$log.report("ABORT enviado para #{$hostnames[i]}:#{$portas[i]}....\n",1)
	end	
end
# enviando commit para um servidor para alterar o dado
def sendCommit(i)
	$log.report("enviando um COMMIT para o #{$socket[i]}\n",1)
	$socket[i].send("COMMIT",0)	
end

def setKey(numServers)
	okArray=[]
	
	openSocket(numServers)
		
	numServers.times do |i|
		$log.report("\n",1)
		$log.report("Enviando requisição para #{$hostnames[i]}:#{$portas[i]}...\n",1)
		$socket[i].send("SETKEY",0)
		$log.report("Requisição SETKEY enviada. Aguardando resposta...\n",1)
		resposta = $socket[i].recv(100)
		okArray = requestOkOrNok(resposta, i)				
	end
	
	$log.report("\n",0)	
	if okArray.size<numServers
		sendAbort(okArray)	
	else
		# enviar COMMIT com a alteração pra todo mundo.
		$log.report("Digite a nova palavra-chave:\n",1)
		keyword = gets.chomp
		$log.report("A palavra chave digita é: #{keyword}\n",1)
		numServers.times do |i|
			sendCommit(i)
			confirmacao = $socket[i].recv(100)
			$log.report("recebendo a confirmação #{confirmacao} do #{$socket[i]}\n",0)
			if confirmacao=="ACK"
				$socket[i].send(keyword, 0)
				$log.report("Palavra-chave '#{keyword}' enviada para o host #{$hostnames[i]}:#{$portas[i].to_i} com sucesso!\n",1)
			else
				$log.report("Falha ao receber confirmação do servidor.\n",1)
				$log.report("Mensagem do servidor: '#{confirmacao}'.\n",1)
			end					
		end
	end

	closeSocket	
end

def getKey(numServers)
	okArray=[]

	openSocket(numServers)

	numServers.times do |i| # envia GETFILE
		$log.report("\n",1)
		$log.report("Enviando requisição para #{$hostnames[i]}:#{$portas[i]}...\n",1)
		$socket[i].send("GETKEY",0)
		$log.report("Requisição GETKEY enviada. Aguardando resposta...\n",1)
		resposta = $socket[i].recv(100)
		okArray = requestOkOrNok(resposta, i)
	end

	$log.report("\n",0)
	if okArray.size<numServers
		sendAbort(okArray)
	else
		# enviar COMMIT com a alteração pra todo mundo.
		$log.report("\n",0)
		keyArray = []
		numServers.times do |i|
			sendCommit(i)
			keyArray[i] = $socket[i].recv(100)
			$log.report("Palavra-chave recebida do host #{$hostnames[i]}:#{$portas[i].to_i} com sucesso!\n ",1)
		end
		if keyArray.uniq.length > 1
			$log.report("As Palavras-chaves recebidas são diferentes.\n",1)
			numServers.times do |i|
				$log.report("Palavra-chave recebida de #{$hostnames[i]}:#{$portas[i].to_i}:\n",1)
				$log.report(keyArray[i],0)
				$log.report("\n",1)
			end
		else
			$log.report("As Palavras-chaves recebidas são iguais.\n",1)
			$log.report("Palavra-chave:\n ",1)
			$log.report(keyArray.first,1)
			$log.report("\n",1)
		end
	end
	
	closeSocket
	
end

def getFile(numServers)
	okArray=[]

	openSocket(numServers)
	numServers.times do |i| # envia GETFILE
		$log.report("\n",0)
			$log.report("Enviando requisição para #{$hostnames[i]}:#{$portas[i]}...\n",1)
		$socket[i].send("GETFILE",0)
		$log.report("Requisição GETFILE enviada. Aguardando resposta...\n",1)
		resposta = $socket[i].recv(100)
		okArray = requestOkOrNok(resposta, i)
	end

	$log.report("\n",0)
	if okArray.size<numServers
		sendAbort(okArray)
	else
		# enviar COMMIT com a alteração pra todo mundo.
		arqArray = []
		numServers.times do |i|
			sendCommit(i)
				tamArq = $socket[i].recv(100).to_i
			$socket[i].send("ACK",0)
			arqArray[i] = $socket[i].recv(tamArq)
			$log.report("Arquivo de #{arqArray[i].size} bytes recebido do host #{$hostnames[i]}:#{$portas[i].to_i} com sucesso! ",1)
		end
		if arqArray.uniq.length > 1
			puts "Arquivos recebidos são diferentes."
			numServers.times do |i|
				$log.report("Arquivo recebido de #{$hostnames[i]}:#{$portas[i].to_i}:\n",1)
				$log.report("#{arqArray[i]}\n",1)
				$log.report("\n",1)
			end
		else
			$log.report("Arquivos recebidos são iguais.\n",1)
			$log.report("Arquivo recebido:\n",1)
			$log.report("#{arqArray.first}\n",1)
			$log.report("\n",1)
		end
	end
	
	closeSocket
end

# FIM METODOS
$log = Log.new("cliente.log")
$log.report("Cliente \n",1)
opcao = 0
getServidores(numServers)
system "clear"
while opcao!=4
	printServersConect(numServers)

	$log.printMenu

	opcao = gets.chomp.to_i
	$log.report("opcao digitada #{opcao}",0)
	system("clear")
	case opcao
		when 1 # SETKEY
			setKey(numServers)
		when 2 # GETKEY
			getKey(numServers)		
		when 3 # GETFILE
			getFile(numServers)
		when 4			
		else # EXIT
			$log.report("Opcao inválida\n",1)
	end

	$log.report("\n",1)
end
$log.report("Saindo do Cliente.\n",0)
$log.close


