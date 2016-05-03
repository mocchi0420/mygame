# encoding: utf-8
$:.unshift(File.dirname(File.expand_path(__FILE__)))
require 'csv'
require 'singleton'
require 'dxruby'
require 'json'
require 'pp'

require './Damage.rb'

# ******************************************
# ==== ゲーム内で使用するスキル用の機能 ====
# ******************************************

module BaseDamage
	#ダメージ補正の決定
	Gradient_lower = 0.5
	Gradient_higher = 2.0
	Gradient_corrected = 0.6
	Random_lower = 70
	Random_higher = 130
	Critical_probability = 15
	
	def calc_basedamage(from, to, opts={})
		# 各種補正計算
		param_corr = from.param_correction(to)
		attribute_corr = from.attribute_correction(to)
		random_corr = from.random_correction(opts[:random])
		critical_corr = from.critical_correction(opts[:critical])
		#amp = {type: "SKILL", target: "CUTE", rate: 3.0}
		s_type = opts[:skill_type]
		send_s = opts[:send_skills]
		rec_s = opts[:receive_skills]
	
		#ダメージ算出
		damage = from.current_power *
					param_corr[:rate] *
					attribute_corr[:rate] *
					random_corr[:rate] *
					critical_corr[:rate] * 0.5

		#ダメージオブジェクトに渡すオプションの用意
		opts = {
			damage: damage.to_i, 
			reference: param_corr,
			skill_name: opts[:skill_name],
			attribute: attribute_corr, 
			critical: critical_corr, 
			skill_type: s_type, 
			random: random_corr, 
		}
	
		return Damage.new(from, to, opts)
	end
	
	def calc_fixdamage(from, to, damage, opts={})
		# 各種補正計算
		s_type = opts[:skill_type]
		send_s = opts[:send_skills]
		rec_s = opts[:receive_skills]

		#ダメージオブジェクトに渡すオプションの用意
		opts = {
			damage: damage.to_i, 
			skill_name: opts[:skill_name],
			skill_type: s_type
		}
	
		return Damage.new(from, to, opts)
	end
	
	
	# パラメータ補正値の算出
	def param_correction(target)
		index = self.current_power.to_f/(target.current_deffense.to_f)	 #ダメージ基準値は攻撃力/防御力
		rate = index
		if index < Gradient_lower
			rate = Gradient_corrected * index + (Gradient_lower- Gradient_corrected * Gradient_lower)
		end
		if index > Gradient_higher
			rate = Gradient_corrected * index + (Gradient_higher - Gradient_corrected * Gradient_higher)
		end
		ref = {attack: self.current_power, deffense: target.current_deffense, rate: rate}
		return ref
	end

	# 属性補正値の算出
	def attribute_correction(target)
		rate = 1.0
		send_type = self.get_attribute.downcase
		receive_type = target.get_attribute.downcase
		
		# 今後の課題：後で展開済みのデータを用意するかを思案
		table = CSV.table("./data/atr_table.csv").each_with_object({}) do |data, my_hash|
			my_hash[data[:attribute].downcase.to_sym] = data.to_hash.reject{|key,_| key == :attribute}
		end
		if table[send_type.to_sym] != nil
			rate = table[send_type.to_sym][receive_type.to_sym] if table[send_type.to_sym][receive_type.to_sym] != nil
		end
		return {send_type: send_type, receive_type: receive_type, rate: rate}
	end
	
	# 乱数補正値の算出
	def random_correction(opts={})
		random = Random.new
		rate_lower = (opts[:rate_lower] != nil) ? opts[:rate_lower] : Random_lower
		rate_higher = (opts[:rate_higher] != nil) ? opts[:rate_higher] : Random_higher
		rate = random.rand(rate_lower..rate_higher).to_f/100.0
		
		if opts[:decision] == false then
			ret = {decision: false, rate: 1.00, rate_higher: (rate_higher.to_f/100.0), rate_lower: (rate_lower.to_f/100.0)}
		else 
			ret = {decision: true, rate: rate, rate_higher: (rate_higher.to_f/100.0), rate_lower: (rate_lower.to_f/100.0)}
		end
		return ret
	end
	
	# クリティカル補正値の算出
	def critical_correction(opts={rate: 2.0, force_critical: nil, probablity: Critical_probability})

		#各種データの読み込み
		if opts[:rate] != nil 
			rate = opts[:rate]
		else
			rate = 2.0
		end
		
		if opts[:force_critical] != nil 
			force_critical = opts[:force_critical]
		else
			force_critical = nil
		end
		
		if opts[:probablity] != nil 
			prob = opts[:probablity]
		else
			prob = Critical_probability
		end		
		
		# クリティカル判定用の乱数としきい値の用意
		random = Random.new
		dtrm = random.rand(1..100)
		
		# クリティカル判定
		if force_critical == true
			ret = {decision: true, probability: prob, force_critical: true, rate: rate}
		elsif  force_critical == false
			ret = {decision: false, probability: prob, force_critical: false, rate: 1.0}
		else
			if dtrm <= prob 
				ret = {decision: true, probability: prob, force_critical: nil, rate: rate}
			else
				ret = {decision: false, probability: prob, force_critical: nil, rate: 1.0}
			end		
		end
		return ret
	end

end


#スキルクラスの大元
class Skill

end

#スキルを使う側が責務を持つスキル
class SendSkill < Skill


	def attack()
	
	end

end

#スキルを受ける側が責務を持つスキル
class ReceiveSkill < Skill

end

