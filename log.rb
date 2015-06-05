# encoding: utf-8

#---------------------------------------------------------------#
# 						log.rb
#    Classe em ruby que gera um arquivo com o log de um programa
#    Objetivo: Aulixiar a compreensão da executação do protocolo
# 			   2PC.    
#    Autores: Evelim Carla Ribeiro
# 	 		  Lucas Affonso Xavier de Morais
#    Disciplina: Redes de computadores II
#    Bacharelado Ciência da Computação
#    Departamento de Informática
#    Universidade Federal do Paraná
#    Ano: 2015
#--------------------------------------------------------------#  

class Log
	# inicializa a o log abrindo o arquivo e imprimindo um cabeçalho
	# no arquivo
	def initialize(filename)
		@file = File.open(filename, "w+")
		self.report(" -----------------------------------------------------------------------\n",0)
		self.report("| Prof. Elias P. Duarte Jr.  -  Disciplina Redes 2                      |\n",0)
		self.report("| Trabalho que implementa a Consistência de Dados com 2PC Simplificado  |\n",0)
		self.report(" -----------------------------------------------------------------------\n",0)
	end

	# imprime o menu do cliente do protocolo 2PC
	def printMenu
		self.report("
		Escolha uma opção
		1 - Trocar palavra-chave.
		2 - Ver palavra-chave.
		3 - Ver arquivo.
		4 - Sair.
		? ", 1)		
	end

	# imprime uma msg no arquivo
	def report(msg, stdout) 
		@file.print msg
		if (stdout==1)
			# puts "entrei"
			print msg
		end
	end

	# fecha o arquivo de log
	def close
		@file.close
	end
end