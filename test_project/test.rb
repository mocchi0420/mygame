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
		opts={
			random:{decision: true, rate_higher:500, rate_lower: 300}, 
			skill_type: [:normal_attack], 
			skill_name: "攻撃", 
			critical: {rate: 2.0, force_critical: nil, probablity: Critical_probability}, 
			amplify: []
		}
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
		opts={random:{decision: false}, skill_type: [:counter_attack], skill_name: "攻撃反射", critical: {rate: 1.0, force_critical: false, probablity: Critical_probability}}
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

chara_b.counter_mode = true
chara_a.use_actionSkill(:set_reflectMode, chara_b, opts:{type: [:normal_attack]})

chara_b.use_actionSkill(:normal_attack, chara_a)
pp chara_a
pp chara_b


Window.loop do

end
