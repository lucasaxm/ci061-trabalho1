#!/usr/bin/env ruby1.9.1
# encoding: utf-8

#-----------------------------------------------------------#
# 						servidor.rb
#    Script em ruby que executa o servidor no protocolo 2PC
#    Objetivo: Fazer a comunicação entre servidor e cliente
#              e salvar os dados novos que o cliente passa  
#    		   para esse servidor
#    
#    Autores: Evelim Carla Ribeiro
# 	 		  Lucas Affonso Xavier de Morais
#    Disciplina: Redes de computadores II
#    Bacharelado Ciência da Computação
#    Departamento de Informática
#    Universidade Federal do Paraná
#    Ano: 2015
#-----------------------------------------------------------#  

$LOAD_PATH << '.'

require 'socket'               # Get sockets from stdlib
require 'thread'
#require 'awesome_print'
require "vigenere" # vigenere.rb
require "log"

# Constantes
TAM_MAX_MSG = 100

# Variáveis Globais
$port = ARGV[0]
$log = Log.new("servidor#{$port}.log")
$mutex = Mutex.new
$keywordPath = "keyword#{$port}"
$filePath = "crypt#{$port}"
$keyword = ""


class ConnectionHandler
	# estabelece conexão com o cliente
    def initialize(clientId, client)
        @clientId, @client = clientId, client
	    @threadId = "Thread #{Thread.current.object_id}"
		$log.report("\n", 1)
		$log.report("#{@threadId}: Conexão estabelecida com o @cliente #{@clientId}\n",1)
    end

    # envia uma mensagem de Nok para o cliente
    def sendNok
        $log.report("#{@threadId}: Outro @cliente está sendo atendido no momento. Enviando NOK para @cliente #{@clientId}...\n",0)
        @client.send("NOK",0)
        $log.report("#{@threadId}: NOK enviado para @cliente #{@clientId}.\n",1)
    end

    # envia uma mensagem de Ok para o cliente
    def sendOk
		$log.report("#{@threadId}: Enviando OK para @cliente #{@clientId}...\n",0)
		@client.send("OK",0)
		$log.report("#{@threadId}: OK enviado para @cliente #{@clientId}.\n",1)    	
    end

    # mostra mensagem na tela e no log de resposta inválida
    def invalidRequestCommitOrAbort
    	$log.report("#{@threadId}: Requisição recebida: '#{requisicao}'.\n",1)
        $log.report("#{@threadId}: Resposta inválida\n",1)
        $log.report("#{@threadId}: Resposta esperada: COMMIT ou ABORT.\n",1)    	
    end

    # mostra mensagem de operação cancelada no log e na tela
    def abortRequest
    	$log.report("#{@threadId}: Requisição recebida '#{requisicao}'.\n",1)
        $log.report("#{@threadId}: Operacao Cancelada\n",1)    	
    end

    # recebe requisição e chama o metodo que o cliente pediu na requisição
    def processaRequisicao
		$log.report("#{@threadId}: Aguardando requisicao...\n",1)
		requisicao = @client.recv(TAM_MAX_MSG)
		$log.report("#{@threadId}: Requisição recebida: '#{requisicao}'.\n",1)
		case requisicao
		when "SETKEY"
            setKey()
		when "GETKEY"
            getKey()
 		when "GETFILE"
            getFile()
 		else
 			$log.report("#{@threadId}: Resposta inválida.\n",1)
			$log.report("#{@threadId}: (Respostas esperadas: SETKEY, GETKEY, GETFILE.)\n",1)
		end
    end

    # altera a chave que gera a criptografia de um arquivo, que usa a cifra de vigenere.
    def setKey
        if !$mutex.try_lock
            sendNok
        else
            sendOk
            $log.report("#{@threadId}: Aguardando nova requisição do @cliente #{@clientId}...\n",1)
            requisicao = @client.recv(TAM_MAX_MSG)
            if requisicao == "COMMIT"
                @client.send("ACK",0)
                $log.report("#{@threadId}: Requisição recebida: '#{requisicao}'.\n",1)
                oldKey = $keyword
                $keyword = @client.recv(TAM_MAX_MSG)
                $log.report("#{@threadId}: Criptografando arquivo...\n",1)
                File.open($filePath, "r+") do |f|
                    $log.report("Arquivo cifrado com a antiga palavra chave '#{oldKey}':\n",0)
                    $log.report("#{f.read}\n",0)
                    f.rewind
                    $log.report("\n",1)
                    $log.report("Descifrado com a chave '#{oldKey}': \n",0)
                    textoClaro = Vigenere.new(oldKey, f.read).decode
                    $log.report("Arquivo descifrado:\n",0)
                    $log.report("#{textoClaro}\n",0)
                    $log.report("\n",0)
                    f.rewind
                    f.truncate(0)
                    $log.report("Novo arquivo cifrado com a chave '#{$keyword}':\n",0)
                    f.write Vigenere.new($keyword, textoClaro).encode
                    f.rewind
                    $log.report("#{f.read}\n",0)
                    $log.report("\n",1)
                    textoClaro = nil
                end
                $log.report("#{@threadId}: Chave alterada de '#{oldKey}' para '#{$keyword}'.\n",1)
                # $log.report("#{@threadId}: sleeping 10sec.\n",1)
                # sleep 10
                # $log.report("#{@threadId}: wake!\n",1)
                # end	
            elsif requisicao == "ABORT"
                abortRequest
            else 
                invalidRequestCommitOrAbort
            end
            $mutex.unlock
        end
    end

    # envia para o cliente a chave que gera a criptografia do arquivo
    def getKey
        if !$mutex.try_lock
            sendNok
        else
            sendOk
            $log.report("#{@threadId}: Aguardando nova requisição do @cliente #{@clientId}...\n",1)
            requisicao = @client.recv(TAM_MAX_MSG)
            $log.report("#{@threadId}: Requisição recebida: '#{requisicao}'.\n",1)
            if requisicao == "COMMIT"
                @client.send($keyword,0)
                $log.report("#{@threadId}: Palavra-chave '#{$keyword}' enviada para o @cliente #{@clientId} com sucesso!\n",1)
            elsif requisicao == "ABORT"
                abortRequest
            else
                invalidRequestCommitOrAbort
            end
            $mutex.unlock
        end
    end

    # envia o arquivo criptografado para o cliente
    def getFile
        if !$mutex.try_lock
            sendNok
        else
            sendOk
            $log.report("#{@threadId}: Aguardando nova requisição do @cliente #{@clientId}...\n",1)
            requisicao = @client.recv(TAM_MAX_MSG)
            if requisicao == "COMMIT"
                $log.report("#{@threadId}: Requisição recebida: '#{requisicao}'.\n",1)
                File.open($filePath,"r") do |f|
                    $log.report("#{@threadId}: Arquivo de #{f.size} bytes aberto para leitura.\n",1)
                    @client.send(f.size.to_s,0)
                    confirmacao = @client.recv(TAM_MAX_MSG)
                    if confirmacao=="ACK"
                        @client.send(f.read,0)
                        $log.report("#{@threadId}: Arquivo enviado para o @cliente #{@clientId} com sucesso!\n",1)
                    else
                        $log.report("#{@threadId}: Falha ao receber confirmação do @cliente #{@clientId}.\n",1)
                        $log.report("#{@threadId}: Mensagem do servidor: '#{confirmacao}'.\n",1)
                    end
                end
            elsif requisicao == "ABORT"
                abortRequest
            else 
                invalidRequestCommitOrAbort
            end
            $mutex.unlock
        end
    end

    # fecha a conexão do servidor com o cliente 
    def close
 		$log.report("#{@threadId}: Fechando Conexão com o @cliente #{@clientId}.\n",1)
		@client.close
    end
end

# Salva keyword e o arquivo criptografado no disco.
def shut_down
	#salvando chave no arquivo
	$log.report("Salvando palavra chave #{$keyword} no arquivo #{$keywordPath}\n",1)
	key = File.new($keywordPath, "w+")
	key.print $keyword
	key.close

	$log.report("\n",1)
	$log.report("Saindo do Servidor.\n",1)
	$log.report("Bye bye!",0)
	$log.close
end

# carrega chave do arquivo
def processKey
	key = File.new($keywordPath, "r+")
	$keyword = key.read.chomp
	key.close
end

# Encerra o servidor de forma limpa, quando recebe o sinal de termino ctrl+C
Signal.trap("INT") {
    shut_down
    exit
}

# Encerra o servidor de forma limpa, quando recebe o sinal de termino kill
Signal.trap("TERM") {
    shut_down
    exit
}


processKey
# inicia servidor
server = TCPServer.open($port)
$log.report("Servidor: #{$port}\n",1)
contClient = 1 	# id dada para cliente que está sendo atendido
loop {
	# abre uma thread para atender cada cliente recebido
	Thread.start(contClient, server.accept) do |clientId, client|
        handler = ConnectionHandler.new(clientId, client)
        handler.processaRequisicao()
        handler.close()
	end
	contClient+=1
}

