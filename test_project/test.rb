# encoding: utf-8
$:.unshift(File.dirname(File.expand_path(__FILE__)))
require 'csv'
require 'singleton'
require 'dxruby'
require 'json'
require 'pp'

#フォントの設定
font = Font.new(24)  # 第２引数を省略するとＭＳ Pゴシックになります


# ********************************
# ==== ファイル読み書き系機能 ====
# ********************************

#ファイル開いたり書き込んだりする系の処理を全部やらせるためのモジュール
module FileManager
	module_function
	def load_csv(file_name)
		Encoding.default_external = 'UTF-8' #デフォルトがWindows31-Jなのでエンコーディング設定は必須になるので注意！！
		ret = CSV.table("./data/#{file_name}").each_with_object({}) do |data, my_hash|
			my_hash[data[:id]] = data.to_hash
			my_hash[data[:id]][:graph] = my_hash[data[:id]][:graph].to_sym
		end
		return ret
	end
	
	def save_json(file_name, my_hash={})
		Encoding.default_external = 'UTF-8' #デフォルトがWindows31-Jなのでエンコーディング設定は必須になるので注意！！
		File.open("./save/#{file_name}", "w") do |file|
  			file.puts(my_hash.to_json.to_s)
		end
	end
	
	def load_json(file_name)
		Encoding.default_external = 'UTF-8' #デフォルトがWindows31-Jなのでエンコーディング設定は必須になるので注意！！
		tmp = File.open("./save/#{file_name}") do |io|
  			JSON.load(io)
		end
		return tmp
	end
	
	def save_8byte_seq(file_name, my_str="")
		File.open("./save/#{file_name}", "w") do |file|
  			file.puts(my_str.to_s)
		end
	end

	def load_8byte_seq(file_name)
		File.read("./save/#{file_name}").force_encoding("ASCII-8BIT").chomp
	end
end

#暗号化・復号化をやらせるためのモジュール
module MyCipher
	require 'openssl'
	include FileManager
	
	Cipher_type = "AES-256-CBC"

	module_function
	def encrypt_data(data, password, salt, cipher_conf=Cipher_type)
  		cipher = OpenSSL::Cipher::Cipher.new(cipher_conf)
  		cipher.encrypt
  		cipher.pkcs5_keyivgen(password, salt)
  		cipher.update(data) + cipher.final
	end
	
	def decrypt_data(data, password, salt, cipher_conf=Cipher_type)
  		cipher = OpenSSL::Cipher::Cipher.new(cipher_conf)
  		cipher.decrypt
  		cipher.pkcs5_keyivgen(password, salt)
  		cipher.update(data) + cipher.final
	end
	
	def get_salt
		OpenSSL::Random.random_bytes(8)
	end

	#データを直接暗号化して外部ファイルに書き出すよ
	def save_as_encrypted(data, file_name)
		salt = self.get_salt
		pass = Digest::SHA1.hexdigest(salt)
		if data.kind_of?(Hash) == true
			tmp_data = data.to_json
		else
			tmp_data = data
		end
		save_data = self.encrypt_data(tmp_data, pass ,salt)
		set_strings = "Salted__"+salt+"__"+save_data
		FileManager.save_8byte_seq(file_name, set_strings)
	end
	
	#ファイルから直接データを復号してハッシュとして返すよ
	def load_as_decrypted(file_name)
		tmp = FileManager.load_8byte_seq(file_name).split("__")
		pass = Digest::SHA1.hexdigest(tmp[1])
		JSON.parse(self.decrypt_data(tmp[2], pass , tmp[1]))	
	end

end


# ************************************************
# ==== ゲーム内で使用するオブジェクト用の機能 ====
# ************************************************


#ゲームオブジェクトだよ
class GameObject
	#ハッシュから変数を自動生成するよ(eval使っていることに注意)
	def hash_to_instance(opts = {})
	  opts.each do |key, value|
	    eval "@#{key}=value"
	  end
	end
end

class Charactor < GameObject
	attr_reader :current_hp, :current_power, :current_deffense
	attr_accessor :counter_mode

	require './skill.rb'
	include BaseDamage

	def initialize(opts = {})
		hash_to_instance(opts)
		@current_hp = @hp
		@current_power = @power
		@current_deffense = @deffense
		@living = true
		@skill = Skill.new
		@counter_mode = {decision: false, type: []}
	end
	
	def get_hash
		ret = {}
 		instance_variables.each { |var|
  			key = var.to_s.tr('@','')
			value = instance_variable_get(var)
  			ret[key.to_sym] = value
 		}
 		return ret
	end
	
	def receive_damage(damage)
		if @counter_mode[:decision] == true && (damage.skill_type & @counter_mode[:type]) != []
			self.use_counterSkill(:reflect_damage, damage.from, damage.damage)
		else
			@current_hp -= damage.damage
			if @current_hp <= 0 then
				@current_hp = 0
				@living = false
			end

		end
	end
	
	def use_actionSkill(skill_name, target, opts={})
		@skill.send(skill_name, self, target, opts) if self.living? == true && target.living? == true
	end
	
	def use_counterSkill(skill_name, target, damage)
		@skill.send(skill_name, target, self, damage) if self.living? == true && target.living? == true
	end
	
	def get_attribute
		return @attribute
	end
	
	def living?
		return @living
	end
	
	def set_counterMode(type)
		@counter_mode = {decision: true, type: type}
	end
	
end

# ******************************************
# ==== ゲーム内で使用するスキル用の機能 ====
# ******************************************

#スキルクラスの大元
class Skill
	include BaseDamage
	
	def normal_attack(from, to, opts:{type: []})
		opts={random: true, skill_type: [:normal_attack], skill_name: "攻撃", critical: {rate: 2.0, force_critical: nil, probablity: Critical_probability}}
		attack_result = calc_basedamage(from, to, opts)
		pp attack_result
		to.receive_damage(attack_result)
	end
	
	def set_reflectMode(from, to, opts:{type: []})
		if opts[:type].class == Symbol || opts[:type].class == String
			ret = Array.new(opts[:type].to_sym)
		elsif opts[:type].class == Array
			ret = opts[:type]
		else
			ret = []
		end
		from.set_counterMode(ret)
	end

	def reflect_damage(from, to, damage)
		opts={random: false, skill_type: [:counter_attack], skill_name: "攻撃反射", critical: {rate: 1.0, force_critical: false, probablity: Critical_probability}}
		attack_result = calc_fixdamage(from, to, damage, opts)
		pp attack_result
		to.receive_damage(attack_result)
		from.set_counterMode({decision: false, counter_type: []})
	end
end


#スキルを使う側が責務を持つスキル
#class SendSkill < Skill
#end

#スキルを受ける側が責務を持つスキル
#class ReceiveSkill < Skill
#end

class Idle
	include Singleton
	include FileManager
	attr_reader :idle
	
	def initialize
		@idle = FileManager.load_csv('test.csv')
	end
	
	def self.idle
		return self.instance.idle
	end
	
	def self.generate(id)
		return Charactor.new(self.idle[id])
	end

end


hoge = FileManager.load_json("test.txt")
MyCipher.save_as_encrypted(hoge.to_json, "hoge.txt")
miria = Idle.generate(10001)
chama = Idle.generate(10002)
#p miria
#p chama

chama.counter_mode = true
#miria.use_actionSkill(:normal_attack, chama)
miria.use_actionSkill(:set_reflectMode, chama, opts:{type: [:normal_attack]})
#p miria
#p chama

chama.use_actionSkill(:normal_attack, miria)
pp miria
pp chama


Window.loop do

end
