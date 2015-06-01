#!/usr/bin/env ruby1.9.1
# encoding: utf-8

$LOAD_PATH << '.'

require 'socket'               # Get sockets from stdlib
require 'thread'
require 'awesome_print'
require "vigenere" # vigenere.rb

include VigenereCipher

port = ARGV[0]
# dado = "My precious Taz and Toph"
filePath = "teste"

#fazer funcao\/
key = File.new("keyword.txt", "r+")
keyword = key.read.chomp
key.close

filename = "servidor#{port}.txt"
file = File.new(filename, "w+")
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

def threadId
	return "Thread #{Thread.current.object_id}"
end

def shut_down (file, keyword)
	log(file, "\n",1)
	log(file, "Saindo do Servidor.",1)
	#salvando chave no arquivo
	log(file, "Salvando palavra chave #{keyword} no arquivo keyword.txt",1)
	key = File.new("keyword.txt", "w")
	key.puts keyword
	file.close
	key.close
end 

Signal.trap("INT") { 
  shut_down(file, keyword)
  exit 
} 

Signal.trap("TERM") { 
  shut_down(file, keyword)
  exit 
}


#======================#
#    Fim metodos       #
#======================#


log(file, " -----------------------------------------------------------------------",1)
log(file, "| Prof. Elias P. Duarte Jr.  -  Disciplina Redes 2                      |",1)
log(file, "| Trabalho que implementa a Consistência de Dados com 2PC Simplificado  |",1)
log(file, " -----------------------------------------------------------------------",1)
log(file, "Servidor: #{port}",1)

mutex = Mutex.new
contClient = 0
server = TCPServer.open(port)
loop {
#servidor com mais de um cliente
	Thread.start(server.accept) do |client|
		clientId = contClient
		log(file, "", 0)
		log(file, "#{threadId}: Conexão estabelecida com o cliente #{clientId}",0)
		log(file, "#{threadId}: Aguardando requisicao...",0)
		requisicao = client.recv(100)
		log(file, "#{threadId}: Requisição recebida: '#{requisicao}'.",0)
		case requisicao
		when "SETKEY"
			if !mutex.try_lock
				log(file, "#{threadId}: Outro cliente está alterando o dado. Enviando NOK para cliente #{clientId}...",0)
				client.send("NOK",0)
				log(file, "#{threadId}: NOK enviado para cliente #{clientId}.",0)
			else
				log(file, "#{threadId}: Enviando OK para cliente #{clientId}...",0)
				client.send("OK",0)
				log(file, "#{threadId}: OK enviado para cliente #{clientId}.",0)
				log(file, "#{threadId}: Aguardando nova requisição do cliente #{clientId}...",0)
				requisicao = client.recv(100)
				if requisicao == "COMMIT"
					client.send("ACK",0)
					log(file, "#{threadId}: Requisição recebida: '#{requisicao}'.",0)
					oldKey = keyword
					keyword = client.recv(100)
					log(file, "#{threadId}: Criptografando arquivo...",0)
					File.open(filePath, "r+") do |f|
						log(file, "Arquivo cifrado com a antiga palavra chave #{oldKey}:",1)
						log(file, "#{f.read}",1)
						f.rewind
						log(file,"",1)
						log(file, "Descifrado com a chave #{oldKey}: ",1)
						textoClaro = VigenereCipher.decrypt(f.read, oldKey)
						log(file, "Arquivo descifrado:",1)
						log(file, "#{textoClaro}",1)
						log(file, "",1)
						f.rewind
						f.truncate(0)
						log(file, "Novo arquivo cifrado com a chave #{keyword}:",1)
						f.write VigenereCipher.encrypt(textoClaro,keyword)
						f.rewind 
						log(file, "#{f.read}",1)
						log(file, "",0)
						textoClaro = nil
						
					end
					
					log(file, "#{threadId}: Chave alterada de '#{oldKey}' para '#{keyword}'.",0)
					# log(file, "#{threadId}: sleeping 10sec.",0)
					# sleep 10
					# log(file, "#{threadId}: wake!",0)
					# end	
				elsif requisicao == "ABORT"
					log(file, "#{threadId}: Requisição recebida '#{requisicao}'.",0)
					log(file, "#{threadId}: Operacao Cancelada",0)
				else 
					log(file, "#{threadId}: Requisição recebida: '#{requisicao}'.",0)
					log(file, "#{threadId}: Resposta inválida",0)
					log(file, "#{threadId}: Resposta esperada: COMMIT ou ABORT.",0)
				end
				mutex.unlock
			end
		when "GETFILE"
			if !mutex.try_lock
				log(file, "#{threadId}: Outro cliente está alterando o dado. Enviando NOK para cliente #{clientId}...",0)
				client.send("NOK",0)
				log(file, "#{threadId}: NOK enviado para cliente #{clientId}.",0)
			else
				log(file, "#{threadId}: Enviando OK para cliente #{clientId}...",0)
				client.send("OK",0)
				log(file, "#{threadId}: OK enviado para cliente #{clientId}.",0)
				log(file, "#{threadId}: Aguardando nova requisição do cliente #{clientId}...",0)
				requisicao = client.recv(100)
				if requisicao == "COMMIT"
					log(file, "#{threadId}: Requisição recebida: '#{requisicao}'.",0)
					File.open(filePath,"r") do |f|
						log( file, "#{threadId}: Arquivo de #{f.size} bytes aberto para leitura.",0)
						client.send(f.size.to_s,0)
						confirmacao = client.recv(100)
						if confirmacao=="ACK"
							client.send(f.read, 0)
							log(file, "#{threadId}: Arquivo enviado para o cliente #{clientId} com sucesso!",0)
						else
							log(file, "#{threadId}: Falha ao receber confirmação do cliente #{clientId}.",0)
							log(file, "#{threadId}: Mensagem do servidor: '#{confirmacao}'.",0)
						end
					end
				elsif requisicao == "ABORT"
					log(file, "#{threadId}: Requisição recebida '#{requisicao}'.",0)
					log(file, "#{threadId}: Operacao Cancelada",0)
				else 
					log(file, "#{threadId}: Requisição recebida: '#{requisicao}'.",0)
					log(file, "#{threadId}: Resposta inválida",0)
					log(file, "#{threadId}: Resposta esperada: COMMIT ou ABORT.",0)
				end
				mutex.unlock
			end
		when "GETKEY"
			if !mutex.try_lock
				log(file, "#{threadId}: Outro cliente está alterando o dado. Enviando NOK para cliente #{clientId}...",0)
				client.send("NOK",0)
				log(file, "#{threadId}: NOK enviado para cliente #{clientId}.",0)
			else
				log(file, "#{threadId}: Enviando OK para cliente #{clientId}...",0)
				client.send("OK",0)
				log(file, "#{threadId}: OK enviado para cliente #{clientId}.",0)
				log(file, "#{threadId}: Aguardando nova requisição do cliente #{clientId}...",0)
				requisicao = client.recv(100)
				log(file, "#{threadId}: Requisição recebida: '#{requisicao}'.",0)
				if requisicao == "COMMIT"
					client.send(keyword,0)
					log(file, "#{threadId}: Palavra-chave '#{keyword}' enviada para o cliente #{clientId} com sucesso!",0)
				elsif requisicao == "ABORT"
					log(file, "#{threadId}: Operacao Cancelada",0)
				else
					log(file, "#{threadId}: Resposta inválida",0)
					log(file, "#{threadId}: Resposta esperada: COMMIT ou ABORT.",0)
				end
				mutex.unlock
			end
 		else
 			log(file, "#{threadId}: Resposta inválida.",0)
			log(file, "#{threadId}: (Respostas esperadas: SETKEY, GETKEY, GETFILE.)",0)
		end
 		log(file, "#{threadId}: Fechando Conexão com o cliente #{clientId}.",0 )
		
		client.close
	end
	contClient+=1
}

