# encoding: utf-8
$:.unshift(File.dirname(File.expand_path(__FILE__)))
require 'csv'
require 'singleton'
require 'dxruby'
require 'json'
require 'pp'

require './Damage.rb'
require './BaseDamage.rb'

# ******************************************
# ==== ゲーム内で使用するスキル用の機能 ====
# ******************************************


#スキルクラスの大元

class Skill
	include Singleton
	extend BaseDamage
	attr_reader :result
	
	def initialize
	end
	
	def self.use(skill_name, opts={}, block=nil)
		block.call(opts) if block != nil
		#p "================================"
		#pp opts
		#p "================================"

		self.generate_message(skill_name, opts)
	end


	private
	def log
		pp @result
	end
	
	def self.generate_message(skill_name, opts)
		skill_result = self.send(skill_name, opts)
		return skill_result
	end
	
	def self.attack(opts={})
		attack_result = calc_basedamage(opts[:from], opts[:to], opts)
		opts[:to].receive_damage(attack_result)
		return {skill: "attack", damage: attack_result, mess: "#{attack_result.from.name}の攻撃！\n#{attack_result.to.name}にn#{attack_result.damage}のダメージ！"}
	end

	def self.set_reflectMode(opts={})
		if opts[:skill_type].class == Symbol || opts[:skill_type].class == String
			ret = Array.new(opts[:skill_type].to_sym)
		elsif opts[:skill_type].class == Array
			ret = opts[:skill_type]
		else
			ret = []
		end
		opts[:from].set_counterMode(ret)
		return {skill: "set_reflect", reflect_type: ret, mess: "反撃の構えを取った！"}
	end
	
	def self.reflectDamage(opts={})
		attack_result = calc_fixdamage(opts[:from], opts[:to], opts[:damage], opts)
		opts[:to].receive_damage(attack_result)
		opts[:from].set_counterMode({decision: false, counter_type: []})
		return {skill: "reflectDamage", damage: attack_result, mess: "反撃ダメージ！！"}
	end
	
end

