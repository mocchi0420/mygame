# encoding: utf-8
$:.unshift(File.dirname(File.expand_path(__FILE__)))
require 'csv'
require 'singleton'
require 'dxruby'
require 'json'
require 'pp'

#フォントの設定
font = Font.new(24)  # 第２引数を省略するとＭＳ Pゴシックになります

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
	
	#ハッシュを取得するメソッドだよ
	def get_hash
		ret = {}
 		instance_variables.each { |var|
  			key = var.to_s.tr('@','')
			value = instance_variable_get(var)
  			ret[key.to_sym] = value
 		}
 		return ret
	end
	
end

class Charactor < GameObject
	attr_reader :current_hp, :current_power, :current_deffense, :name
	attr_accessor :counter_mode

	require './skill.rb'
	include BaseDamage

	def initialize(opts = {})
		hash_to_instance(opts)
		@name = ""
		@current_hp = @hp
		@current_power = @power
		@current_deffense = @deffense
		@living = true
		#@skill = Skill.new
		@counter_mode = {decision: false, type: []}
	end
	
	def receive_damage(damage)
		if @counter_mode[:decision] == true && (damage.skill_type & @counter_mode[:type]) != []
			#self.use_counterSkill(:reflect_damage, damage.from, damage.damage)
			opts = {
				from: self, 
				to: damage.from, 
				damage: damage.damage,
				random:{decision: false}, 
				skill_type: [:counter_attack], 
				skill_name: "攻撃反射", 
				critical: {rate: 1.0, force_critical: false, probablity: Critical_probability}
			}
			mess = self.use_actionSkill("reflectDamage", opts)
			p mess[:mess]
		else
			@current_hp -= damage.damage
			if @current_hp <= 0 then
				@current_hp = 0
				@living = false
			end

		end
	end
	
	def use_actionSkill(skill_name, opts={})
		Skill.use(skill_name, opts)  if self.living? == true && opts[:to].living? == true
	end

	def use_actionSkill2(skill_name ,opts={}, block=nil)
		Skill.use(skill_name, opts, block)  if self.living? == true && opts[:to].living? == true
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

class Idle
	require './FileManager.rb'
	include Singleton
	include FileManager
	attr_reader :idle
	
	def initialize
		@idle = FileManager.load_csv('test.csv')
		#hoge = FileManager.load_json("test.txt")
		#MyCipher.save_as_encrypted(hoge.to_json, "hoge.txt")
	end
	
	def self.idle
		return self.instance.idle
	end
	
	def self.generate(id)
		return Charactor.new(self.idle[id])
	end

end


chara_a = Idle.generate(10001)
chara_b = Idle.generate(10002)


opts_a = {
	from: chara_a,
	to: chara_b,
	skill_type: [:normal_attack]
}

#chara_a.use_actionSkill2("attack", opts_a)

foo = chara_a.use_actionSkill("set_reflectMode", opts_a)
p foo[:mess]

#pp chara_a

opts_b = {
	from: chara_b,
	to: chara_a,
	random:{decision: true, rate_higher:500, rate_lower: 300}, 
	skill_type: [:normal_attack], 
	skill_name: "攻撃", 
	critical: {rate: 2.0, force_critical: nil, probablity: 2.0}, 
	amplify: []
}

#ブロック内で好きにデータを組み替えれば自由にスキルを変更可能
block = Proc.new do |data|
	#data[:skill_name] = "testtesttest"
	data[:skill_name] = "このスキルはジャックされました"
end

bar = chara_b.use_actionSkill2("attack" ,opts_b, block)
p bar[:mess]
#pp chara_a
#pp chara_b


Window.loop do

end
