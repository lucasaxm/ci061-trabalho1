require 'socket'

3.times do |i|
	puts "Digite o nome do servidor #{i}: "
	hostnames[i]=gets.chomp
	puts "Digite a porta do servidor #{i}: "
	portas[i]=gets.chomp
	socket[hostnames[i]] = TCPSocket.open(hostnames[i], portas[i])
end
puts "Digite blablabla" # parei aqui
s.send(texto,0)
puts s.recv(100)

s.close               # Close the socket when done