# encoding: utf-8

require 'thread'

mutex = Mutex.new

t1 = Thread.new {
	if mutex.try_lock
		puts "Thread 1: tranquei!"
		sleep 10
		puts "Thread 1: liberei"
	else
		sleep 2
		puts "Thread 1: JÁ TA TRANCADO =((("
	end
}

t2 = Thread.new {
	if mutex.try_lock
		puts "Thread 2: tranquei!"
		sleep 10
		puts "Thread 2: liberei"
	else
		sleep 2
		puts "Thread 2: JÁ TA TRANCADO =((("
	end
}

t1.join
t2.join