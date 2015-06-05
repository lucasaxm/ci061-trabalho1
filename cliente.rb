#!/usr/bin/env ruby1.9.1
# encoding: utf-8

#-----------------------------------------------------------#
# 						cliente.rb
#    Script em ruby que executa o cliente no protocolo 2PC
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
require 'socket'
require "awesome_print"
require "client_handler"
require "log"

# instancia cliente conectado a 3 servidores
cliente = ClientHandler.new(3)
opcao = 0
system "clear"
while opcao!=4 # se for igual a opção 4 fecha o programa
	cliente.printConnectedServers
	cliente.log.printMenu
	opcao = gets.chomp.to_i
	cliente.log.report("opcao digitada #{opcao}",0)
	system("clear")

	case opcao
		when 1 # SETKEY
			cliente.setKey
		when 2 # GETKEY
			cliente.getKey		
		when 3 # GETFILE
			cliente.getFile
		when 4			
		else # EXIT
			cliente.log.report("Opcao inválida\n",1)
	end

	cliente.log.report("\n",1)
end

cliente.log.report("Saindo do Cliente.\n",0)
cliente.log.close


