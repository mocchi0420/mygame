# encoding: utf-8
$:.unshift(File.dirname(File.expand_path(__FILE__)))
require 'csv'
require 'singleton'
require 'dxruby'
require 'json'
require 'pp'

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
			my_hash[data[:id]][:graph] = my_hash[data[:id]][:graph].to_sym if my_hash[data[:id]][:graph] != nil
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