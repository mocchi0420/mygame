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
	
	def self.use(skill_name, opts={}, &block)
		tmp = opts
		#block.call(tmp)
		self.send(skill_name, tmp)
	end

	private
	def log
		pp @result
	end
	
	def self.attack(opts={})
		attack_result = calc_basedamage(opts[:from], opts[:to], opts)
		pp attack_result
		opts[:to].receive_damage(attack_result)
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
	end
	
	def self.reflectDamage(opts={})
		attack_result = calc_fixdamage(opts[:from], opts[:to], opts[:damage], opts)
		opts[:to].receive_damage(attack_result)
		opts[:from].set_counterMode({decision: false, counter_type: []})
	end
	
end

