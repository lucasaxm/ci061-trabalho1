#!/usr/bin/env ruby1.9.1
# encoding: utf-8

$LOAD_PATH << '.'

require 'socket'               # Get sockets from stdlib
require 'thread'
require 'awesome_print'
require "vigenere" # vigenere.rb
require "log"

include VigenereCipher

port = ARGV[0]
filePath = "teste"
tamMaxMsg = 100

#fazer funcao\/
key = File.new("keyword.txt", "r+")
$keyword = key.read.chomp
key.close

$log = Log.new("servidor#{port}.log")

# Retorna um identificador para a thread atual.
def threadId
	return "Thread #{Thread.current.object_id}"
end

# Salva keyword e o arquivo criptografado no disco.
def shut_down
	$log.report("\n",1)
	$log.report("Saindo do Servidor.\n",1)
	#salvando chave no arquivo
	$log.report("Salvando palavra chave #{$keyword} no arquivo keyword.txt\n",1)
	key = File.new("keyword.txt", "w+")
	key.puts $keyword
	key.close
	$log.report("Bye bye!",0)
	$log.close
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


$log.report("Servidor: #{port}",1)

mutex = Mutex.new
contClient = 1 	# id dada para cliente que está sendo atendido
server = TCPServer.open(port)
loop {
	# abre uma thread para atender cada cliente recebido
	Thread.start(server.accept) do |client|
		clientId = contClient # atribui um identificador ao cliente
		$log.report("\n", 1)
		$log.report("#{threadId}: Conexão estabelecida com o cliente #{clientId}\n",1)
		$log.report("#{threadId}: Aguardando requisicao...\n",1)
		requisicao = client.recv(tamMaxMsg) 	
		$log.report("#{threadId}: Requisição recebida: '#{requisicao}'.\n",1)
		case requisicao
		when "SETKEY"
			if !mutex.try_lock
				$log.report("#{threadId}: Outro cliente está sendo atendido no momento. Enviando NOK para cliente #{clientId}...\n",0)
				client.send("NOK",0)
				$log.report("#{threadId}: NOK enviado para cliente #{clientId}.\n",1)
			else
				$log.report("#{threadId}: Enviando OK para cliente #{clientId}...\n",0)
				client.send("OK",0)
				$log.report("#{threadId}: OK enviado para cliente #{clientId}.\n",1)
				$log.report("#{threadId}: Aguardando nova requisição do cliente #{clientId}...\n",1)
				requisicao = client.recv(tamMaxMsg)
				if requisicao == "COMMIT"
					client.send("ACK",0)
					$log.report("#{threadId}: Requisição recebida: '#{requisicao}'.\n",1)
					oldKey = $keyword
					$keyword = client.recv(tamMaxMsg)
					$log.report("#{threadId}: Criptografando arquivo...\n",1)
					File.open(filePath, "r+") do |f|
						$log.report("Arquivo cifrado com a antiga palavra chave #{oldKey}:\n",0)
						$log.report("#{f.read}\n",0)
						f.rewind
						$log.report("\n",1)
						$log.report("Descifrado com a chave #{oldKey}: \n",0)
						textoClaro = VigenereCipher.decrypt(f.read, oldKey)
						$log.report("Arquivo descifrado:\n",0)
						$log.report("#{textoClaro}\n",0)
						$log.report("\n",0)
						f.rewind
						f.truncate(0)
						$log.report("Novo arquivo cifrado com a chave #{$keyword}:\n",0)
						f.write VigenereCipher.encrypt(textoClaro,$keyword)
						f.rewind 
						$log.report("#{f.read}\n",0)
						$log.report("\n",1)
						textoClaro = nil
						
					end
					
					$log.report("#{threadId}: Chave alterada de '#{oldKey}' para '#{$keyword}'.\n",1)
					# $log.report("#{threadId}: sleeping 10sec.\n",1)
					# sleep 10
					# $log.report("#{threadId}: wake!\n",1)
					# end	
				elsif requisicao == "ABORT"
					$log.report("#{threadId}: Requisição recebida '#{requisicao}'.\n",1)
					$log.report("#{threadId}: Operacao Cancelada\n",1)
				else 
					$log.report("#{threadId}: Requisição recebida: '#{requisicao}'.\n",1)
					$log.report("#{threadId}: Resposta inválida\n",1)
					$log.report("#{threadId}: Resposta esperada: COMMIT ou ABORT.\n",1)
				end
				mutex.unlock
			end
		when "GETFILE"
			if !mutex.try_lock
				$log.report("#{threadId}: Outro cliente está alterando o dado. Enviando NOK para cliente #{clientId}...\n",0)
				client.send("NOK",0)
				$log.report("#{threadId}: NOK enviado para cliente #{clientId}.\n",1)
			else
				$log.report("#{threadId}: Enviando OK para cliente #{clientId}...\n",1)
				client.send("OK",0)
				$log.report("#{threadId}: OK enviado para cliente #{clientId}.\n",1)
				$log.report("#{threadId}: Aguardando nova requisição do cliente #{clientId}...\n",1)
				requisicao = client.recv(tamMaxMsg)
				if requisicao == "COMMIT"
					$log.report("#{threadId}: Requisição recebida: '#{requisicao}'.\n",1)
					File.open(filePath,"r") do |f|
						$log.report("#{threadId}: Arquivo de #{f.size} bytes aberto para leitura.\n",1)
						client.send(f.size.to_s,0)
						confirmacao = client.recv(tamMaxMsg)
						if confirmacao=="ACK"
							client.send(f.read,0)
							$log.report("#{threadId}: Arquivo enviado para o cliente #{clientId} com sucesso!\n",1)
						else
							$log.report("#{threadId}: Falha ao receber confirmação do cliente #{clientId}.\n",1)
							$log.report("#{threadId}: Mensagem do servidor: '#{confirmacao}'.\n",1)
						end
					end
				elsif requisicao == "ABORT"
					$log.report("#{threadId}: Requisição recebida '#{requisicao}'.\n",1)
					$log.report("#{threadId}: Operacao Cancelada\n",1)
				else 
					$log.report("#{threadId}: Requisição recebida: '#{requisicao}'.\n",1)
					$log.report("#{threadId}: Resposta inválida\n",1)
					$log.report("#{threadId}: Resposta esperada: COMMIT ou ABORT.\n",1)
				end
				mutex.unlock
			end
		when "GETKEY"
			if !mutex.try_lock
				$log.report("#{threadId}: Outro cliente está alterando o dado. Enviando NOK para cliente #{clientId}...\n",0)
				client.send("NOK",0)
				$log.report("#{threadId}: NOK enviado para cliente #{clientId}.\n",1)
			else
				$log.report("#{threadId}: Enviando OK para cliente #{clientId}...\n",1)
				client.send("OK",0)
				$log.report("#{threadId}: OK enviado para cliente #{clientId}.\n",1)
				$log.report("#{threadId}: Aguardando nova requisição do cliente #{clientId}...\n",1)
				requisicao = client.recv(tamMaxMsg)
				$log.report("#{threadId}: Requisição recebida: '#{requisicao}'.\n",1)
				if requisicao == "COMMIT"
					client.send($keyword,0)
					$log.report("#{threadId}: Palavra-chave '#{$keyword}' enviada para o cliente #{clientId} com sucesso!\n",1)
				elsif requisicao == "ABORT"
					$log.report("#{threadId}: Operacao Cancelada\n",1)
				else
					$log.report("#{threadId}: Resposta inválida\n",1)
					$log.report("#{threadId}: Resposta esperada: COMMIT ou ABORT.\n",1)
				end
				mutex.unlock
			end
 		else
 			$log.report("#{threadId}: Resposta inválida.\n",1)
			$log.report("#{threadId}: (Respostas esperadas: SETKEY, GETKEY, GETFILE.)\n",1)
		end
 		$log.report("#{threadId}: Fechando Conexão com o cliente #{clientId}.\n",1)
		
		client.close
	end
	contClient+=1
}

