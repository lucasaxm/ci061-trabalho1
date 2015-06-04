# encoding: utf-8
class Log

	def initialize(filename)
		@file = File.open(filename, "w+")
		self.report(" -----------------------------------------------------------------------\n",0)
		self.report("| Prof. Elias P. Duarte Jr.  -  Disciplina Redes 2                      |\n",0)
		self.report("| Trabalho que implementa a Consistência de Dados com 2PC Simplificado  |\n",0)
		self.report(" -----------------------------------------------------------------------\n",0)
	end

	def printMenu
		self.report("
		Escolha uma opção
		1 - Trocar palavra-chave.
		2 - Ver palavra-chave.
		3 - Ver arquivo.
		4 - Sair.
		? ", 1)		
	end

	def report(msg, stdout) # editando aqui
		# puts "msg=#{msg}"
		# puts "stdout=#{stdout}"
		# puts stdout==1
		@file.print msg
		if (stdout==1)
			# puts "entrei"
			print msg
		end
		# case val
		# 	when 0
		# 		$file.puts msg
		# 		puts msg
		# 	when 1
		# 		$file.puts msg
		# 	when 2
		# 		puts msg
		# 	when 3
		# 		$file.print msg
		# 		print msg
		# 	when 4
		# 		print msg
		# 	else			
		# 		puts "Erro no logger"		
		# end
	end

	def close
		@file.close
	end
end