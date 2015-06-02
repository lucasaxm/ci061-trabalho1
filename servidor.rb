#!/usr/bin/env ruby1.9.1
# encoding: utf-8

$LOAD_PATH << '.'

require 'socket'               # Get sockets from stdlib
require 'thread'
require 'awesome_print'
require "vigenere" # vigenere.rb

include VigenereCipher

port = ARGV[0]
filePath = "teste"
tamMaxMsg = 100

#fazer funcao\/
key = File.new("keyword.txt", "r+")
$keyword = key.read.chomp
key.close

filename = "servidor#{port}.txt"
$file = File.new(filename, "w+")
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

# Retorna um identificador para a thread atual.
def threadId
	return "Thread #{Thread.current.object_id}"
end

# Salva keyword e o arquivo criptografado no disco.
def shut_down
	log("\n",1)
	log("Saindo do Servidor.",1)
	#salvando chave no arquivo
	log("Salvando palavra chave #{$keyword} no arquivo keyword.txt",1)
	key = File.new("keyword.txt", "w")
	key.puts $keyword
	key.close
	$file.close
	log("Bye bye!",2)
end

Signal.trap("INT") { 
  shut_down
  exit 
} 

Signal.trap("TERM") { 
  shut_down
  exit 
}


#======================#
#    Fim metodos       #
#======================#


log(" -----------------------------------------------------------------------",1)
log("| Prof. Elias P. Duarte Jr.  -  Disciplina Redes 2                      |",1)
log("| Trabalho que implementa a Consistência de Dados com 2PC Simplificado  |",1)
log(" -----------------------------------------------------------------------",1)
log("Servidor: #{port}",1)

mutex = Mutex.new
contClient = 1 	# id dada para cliente que está sendo atendido
server = TCPServer.open(port)
loop {
	# abre uma thread para atender cada cliente recebido
	Thread.start(server.accept) do |client|
		clientId = contClient # atribui um identificador ao cliente
		log("", 0)
		log("#{threadId}: Conexão estabelecida com o cliente #{clientId}",0)
		log("#{threadId}: Aguardando requisicao...",0)
		requisicao = client.recv(tamMaxMsg) 	
		log("#{threadId}: Requisição recebida: '#{requisicao}'.",0)
		case requisicao
		when "SETKEY"
			if !mutex.try_lock
				log("#{threadId}: Outro cliente está sendo atendido no momento. Enviando NOK para cliente #{clientId}...",0)
				client.send("NOK",0)
				log("#{threadId}: NOK enviado para cliente #{clientId}.",0)
			else
				log("#{threadId}: Enviando OK para cliente #{clientId}...",0)
				client.send("OK",0)
				log("#{threadId}: OK enviado para cliente #{clientId}.",0)
				log("#{threadId}: Aguardando nova requisição do cliente #{clientId}...",0)
				requisicao = client.recv(tamMaxMsg)
				if requisicao == "COMMIT"
					client.send("ACK",0)
					log("#{threadId}: Requisição recebida: '#{requisicao}'.",0)
					oldKey = $keyword
					$keyword = client.recv(tamMaxMsg)
					log("#{threadId}: Criptografando arquivo...",0)
					File.open(filePath, "r+") do |f|
						log("Arquivo cifrado com a antiga palavra chave #{oldKey}:",1)
						log("#{f.read}",1)
						f.rewind
						log("",1)
						log("Descifrado com a chave #{oldKey}: ",1)
						textoClaro = VigenereCipher.decrypt(f.read, oldKey)
						log("Arquivo descifrado:",1)
						log("#{textoClaro}",1)
						log("",1)
						f.rewind
						f.truncate(0)
						log("Novo arquivo cifrado com a chave #{$keyword}:",1)
						f.write VigenereCipher.encrypt(textoClaro,$keyword)
						f.rewind 
						log("#{f.read}",1)
						log("",0)
						textoClaro = nil
						
					end
					
					log("#{threadId}: Chave alterada de '#{oldKey}' para '#{$keyword}'.",0)
					# log("#{threadId}: sleeping 10sec.",0)
					# sleep 10
					# log("#{threadId}: wake!",0)
					# end	
				elsif requisicao == "ABORT"
					log("#{threadId}: Requisição recebida '#{requisicao}'.",0)
					log("#{threadId}: Operacao Cancelada",0)
				else 
					log("#{threadId}: Requisição recebida: '#{requisicao}'.",0)
					log("#{threadId}: Resposta inválida",0)
					log("#{threadId}: Resposta esperada: COMMIT ou ABORT.",0)
				end
				mutex.unlock
			end
		when "GETFILE"
			if !mutex.try_lock
				log("#{threadId}: Outro cliente está alterando o dado. Enviando NOK para cliente #{clientId}...",0)
				client.send("NOK",0)
				log("#{threadId}: NOK enviado para cliente #{clientId}.",0)
			else
				log("#{threadId}: Enviando OK para cliente #{clientId}...",0)
				client.send("OK",0)
				log("#{threadId}: OK enviado para cliente #{clientId}.",0)
				log("#{threadId}: Aguardando nova requisição do cliente #{clientId}...",0)
				requisicao = client.recv(tamMaxMsg)
				if requisicao == "COMMIT"
					log("#{threadId}: Requisição recebida: '#{requisicao}'.",0)
					File.open(filePath,"r") do |f|
						log("#{threadId}: Arquivo de #{f.size} bytes aberto para leitura.",0)
						client.send(f.size.to_s,0)
						confirmacao = client.recv(tamMaxMsg)
						if confirmacao=="ACK"
							client.send(f.read, 0)
							log("#{threadId}: Arquivo enviado para o cliente #{clientId} com sucesso!",0)
						else
							log("#{threadId}: Falha ao receber confirmação do cliente #{clientId}.",0)
							log("#{threadId}: Mensagem do servidor: '#{confirmacao}'.",0)
						end
					end
				elsif requisicao == "ABORT"
					log("#{threadId}: Requisição recebida '#{requisicao}'.",0)
					log("#{threadId}: Operacao Cancelada",0)
				else 
					log("#{threadId}: Requisição recebida: '#{requisicao}'.",0)
					log("#{threadId}: Resposta inválida",0)
					log("#{threadId}: Resposta esperada: COMMIT ou ABORT.",0)
				end
				mutex.unlock
			end
		when "GETKEY"
			if !mutex.try_lock
				log("#{threadId}: Outro cliente está alterando o dado. Enviando NOK para cliente #{clientId}...",0)
				client.send("NOK",0)
				log("#{threadId}: NOK enviado para cliente #{clientId}.",0)
			else
				log("#{threadId}: Enviando OK para cliente #{clientId}...",0)
				client.send("OK",0)
				log("#{threadId}: OK enviado para cliente #{clientId}.",0)
				log("#{threadId}: Aguardando nova requisição do cliente #{clientId}...",0)
				requisicao = client.recv(tamMaxMsg)
				log("#{threadId}: Requisição recebida: '#{requisicao}'.",0)
				if requisicao == "COMMIT"
					client.send($keyword,0)
					log("#{threadId}: Palavra-chave '#{$keyword}' enviada para o cliente #{clientId} com sucesso!",0)
				elsif requisicao == "ABORT"
					log("#{threadId}: Operacao Cancelada",0)
				else
					log("#{threadId}: Resposta inválida",0)
					log("#{threadId}: Resposta esperada: COMMIT ou ABORT.",0)
				end
				mutex.unlock
			end
 		else
 			log("#{threadId}: Resposta inválida.",0)
			log("#{threadId}: (Respostas esperadas: SETKEY, GETKEY, GETFILE.)",0)
		end
 		log("#{threadId}: Fechando Conexão com o cliente #{clientId}.",0 )
		
		client.close
	end
	contClient+=1
}

