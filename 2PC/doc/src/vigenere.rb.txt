#!/usr/bin/env ruby
# -*- coding: utf-8 -*-
# 
# Copyright by Scott Severance
# 
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
# 
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
# 
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
# THE SOFTWARE.

# This is a library to implement the Vigenère Cipher
# <https://en.wikipedia.org/wiki/Vigen%C3%A8re_cipher>.
# 
# Compatibility note:
# -------------------
# If you want to use a random key, *and* you don't supply a seed, this library
# depends on a UNIX-like system (such as Linux). If you don't need that
# particular feature, you should be able to use any system with a Ruby 1.8 or
# 1.9 interpreter. This library is untested with Ruby 2.0.

require 'enumerator'

# Exception raised if the key is set before the text.
class NoTextError < StandardError
end

# This class handles encoding and decoding text using the
# Vigenère Cipher.
class Vigenere
  
  # For convenience, you can set the options in the constructor. All
  # values are optional (though they need to be specified eventually).
  # 
  # Arguments:
  # key:             The cipher key
  # text:            The text to be encoded or decoded
  # chars_per_group: If non-nil, output will be grouped into groups of
  #                    this many characters.
  # 
  # When setting the text and the key, this class will automatically
  # convert its input to uppercase and strip all non-alphabetic
  # characters.
  def initialize(key = nil, text = nil, chars_per_group = nil)
    @letter_set = %w[A B C D E F G H I J K L M N O P Q R S T U V W X Y Z]
    @table, @letter_indices = make_tabula_recta
    @chars_per_group = chars_per_group
    self.text = text unless text.nil?
    self.key = key unless key.nil?
    @seeded = nil
  end
  
  # Reader methods for various instance variables.
  attr_reader :chars_per_group, :cipher_text, :letter_set, :plain_text, :seed, :table
  
  # Set the number of characters per output group. It is an error to set
  # this to 0. Set to nil to disable grouping.
  def chars_per_group=(n)
    raise ArgumentError, "Can't have 0 characters per group; set to nil to disable" if n == 0
    @chars_per_group = n
  end
  
  # Decode the stored text using the stored key. Of course, both must be
  # set prior to calling this method.
  def decode
    transform :decode
  end
  
  # Encode the stored text using the stored key. Of course, both must be
  # set prior to calling this method.
  def encode
    transform :encode   
  end
  
  # Reads the specified file and sets its contents as the text.
  def file=(filename)
    File.open(filename) do |f|
      self.text = f.read
    end
    self.text
  end
  
  # Provides sensible output on inspect and when running in irb.
  def inspect
    "<Vigenere: @text=%s, @key=%s, @seed=%s>" % [
      (@text) ? @text.inspect : 'nil',
      (@key)  ? @key.inspect  : 'nil',
      (@seed) ? @seed.inspect : 'nil',
    ]
  end
  
  # Returns the current key.
  def key
    add_spaces(@key, chars_per_group)
  end
  
  # Sets the key. Raises NoTextError unless the text is set first.
  # Automatically converts the key to uppercase and discards
  # non-alphabetic characters.
  def key=(key)
    begin
      txt_len = @text.split('').length # A bug in Ruby 1.8 sometimes causes
                                       # String#length to return an incorrect value
    rescue NoMethodError
      raise NoTextError, "You must set the text before setting a key."
    end
    @original_key = key
    key = normalize_text(key).split('')
    until key.length >= txt_len
      key += key
    end
    @key = key[0...txt_len].join('')
    @key
  end
  
  # Sets the alphabet to use. Takes an array of uppercase (if
  # applicable) letters. Note: normalize_text can only auto-uppercase
  # the letters of the English alphabet. That means that if you use a
  # non-English alphabet, you'll have to manually convert your text and
  # key to uppercase.
  def letter_set=(array)
    @letter_set = array
    @table, @letter_indices = make_tabula_recta
  end
  
  # Makes the tabula_recta--the cipher table. Returns an array of the
  # table itself and a hash mapping letters to indices.
  def make_tabula_recta
    letters = @letter_set.dup
    table = []
    letters.length.times do
      table.push letters.dup
      letters.push letters.shift
    end
    indices = {}
    letters = letters.each_with_index { |letter, i| indices[letter] = i }
    [table, indices]
  end
  
  # Generates a pseudorandom key the same length as the text. Sets and
  # returns the key.
  # 
  # If a seed has been set via the seed= method, then this method
  # generates a repeatable pseudorandom number based on the seed. If the
  # seed has not been set, or has been explicitly set to nil, then this
  # method generates the most random number possible on the system.
  # 
  # Compatibility note: In cases where @seed is nil (meaning a seed has not been
  # set via the seed= method), this implementation depends on the underlying
  # system having a 'dd' command and a '/dev/random'. This most likely means
  # that this case will only work on a UNIX-like system. It has only been tested
  # on Linux.
  def random_key
    text_length = @text.split('').length # See explanation in method key=.
    if @seed
      key = []
      text_length.times do
        key.push(@table[0][rand(@letter_set.length)])
      end
    else
      cmd = "dd if=/dev/random bs=1 count=#{text_length}"
      key = `#{cmd} 2>/dev/null`.chomp.unpack("C#{text_length}")
      key.collect! { |i| @table[0][i % @letter_set.length] }
    end
    self.key = key.join ''
  end
  
  # To use a seeded random number for a random key (so that the key can
  # be replayed, call this method with an Integer. To use a more random
  # key, call it with nil.
  def seed=(value)
    srand(value) if value.kind_of? Integer
    @seed = value
  end
  
  # Returns the current text.
  def text
    add_spaces(@text, @chars_per_group)
  end
  
  # Sets the text. Automatically converts text to uppercase and discards
  # non-alphabetic characters.
  def text=(text)
    @text = normalize_text text
    self.key= @original_key if @original_key
  end
  
  # Handles conversion to a string. Returns the text. Text is in
  # whichever state it was last converted to.
  def to_s
    text
  end
  
  # The following methods are private.
  private
  
  # Adds spaces to str every chars_per_group characters.
  def add_spaces(str, chars_per_group = nil)
    return str if chars_per_group.nil?
    str = str.split ''
    out = []
    str.each_slice(chars_per_group) do |group|
      group.push ' '
      out.push group.join('')
    end
    out.join('').strip
  end
  
  # Converts text to uppercase and discards non-alphabetic characters.
  def normalize_text(text)
    letters = text.upcase.split ''
    letters.delete_if { |x| ! @table[0].include?(x) }
    letters.join ''
  end
  
  # Performs the actual encoding or decoding. The argument direction is
  # one of :encode or :decode.
  def transform(direction)
    text_letters = @text.split ''
    key_letters = @key.split ''
    transformed = []
    case direction
      when :encode
        text_letters.each_with_index do |letter, i|
          index1 = @letter_indices.fetch(key_letters.fetch(i))
          index2 = @letter_indices.fetch(letter)
          transformed.push @table.fetch(index1).fetch(index2)
        end
        @plain_text = @text
        @cipher_text = add_spaces(transformed.join(''), @chars_per_group)
        @text = normalize_text @cipher_text
        return @cipher_text
      when :decode
        text_letters.each_with_index do |letter, i|
          index = @letter_indices.fetch(letter) - @letter_indices.fetch(key_letters.fetch(i))
          transformed.push @table[0].fetch(index)
        end
        @plain_text = add_spaces(transformed.join(''), @chars_per_group)
        @cipher_text = self.text
        @text = normalize_text @plain_text
        return @plain_text
      else
        raise ArgumentError, "direction must be either :encode or :decode"
    end
  end
end

# Testing code. Only executed if this file is executed directly. If this
# file is require'd, this code doesn't run.
# 
# To run the testing code:
#     ./vigenere.rb text key [chars-per-group]
if $0 == __FILE__
  raise "Must supply at least 2 command line arguments" if ARGV.length < 2
  a = Vigenere.new
  a.text = ARGV[0]
  a.key = ARGV[1]
  a.chars_per_group = ARGV[2].to_i if ARGV.length >= 3
  
  puts "Using supplied key:"
  puts "      Plain text : #{a}"
  puts "    Supplied key : #{a.key}"
  puts "    Encoded text : #{a.encode}"
  puts "    Decoded text : #{a.decode}"
  
  a.seed = 7629384752639857236945827346952837652938752392938742837462598
  a.random_key
  
  puts "\nUsing random (seeded) key:"
  puts "      Plain text : #{a}"
  puts "      Random key : #{a.key}"
  puts "    Encoded text : #{a.encode}"
  puts "    Decoded text : #{a.decode}"
end
