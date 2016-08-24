# encoding: utf-8
$:.unshift(File.dirname(File.expand_path(__FILE__)))
require 'csv'
require 'singleton'
require 'dxruby'
require 'json'
require 'pp'

class StringData
	require './FileManager.rb'
	include Singleton
	include FileManager
	attr_reader :string_data
	
	def initialize
		@string_data = FileManager.load_csv('StringData.csv')
	end
	
	def self.get_string(code, opts={})
		ret = code
		self.instance.string_data.each do |_, data|
			ret = data[:string] if data[:index] == code
		end
		ret.scan(/\{[0-9]+\}/).each.with_index(0) do |data, idx|
			ret.gsub!(data, opts[:set_words][idx]) if opts[:set_words].length > idx
		end
		return ret
	end
	
	def self.get_str_object(code, opts={})
		str = self.get_string(code, opts)
		font = Font.new(24)  # 第２引数を省略するとＭＳ Pゴシックになります
		Window.draw_font_ex(opts[:x], opts[:y], str, font)
		#Window.draw_font_ex(opts[:x], opts[:y], str, font, option)
	end
end


puts "--------------------------------------------------------------"
puts StringData.get_string("~deal_damage", {set_words: ["ああああ", "1000"], x: 100, y: 100})
puts "--------------------------------------------------------------"



Window.loop do
	StringData.get_str_object("~deal_damage", {set_words: ["ああああ", "1000"], x: 100, y: 100})
end
