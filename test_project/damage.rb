# encoding: utf-8
$:.unshift(File.dirname(File.expand_path(__FILE__)))

# ************************************************
# ==== ダメージオブジェクト生成のためのクラス ====
# ************************************************

class Damage
	#定数
	Default_critical_rate = 2.0

	#インスタンス変数
	private
	attr_writer :from, :to, :damage, :reference, :attribute, :critical, :amplify , :skill_type, :random, :send_skills, :receive_skills, :skill_name

	public
	attr_reader :from, :to, :damage, :reference, :attribute, :critical, :amplify , :skill_type, :random, :send_skills, :receive_skills, :skill_name
	
	#メソッド
	#コンストラクタ
	def initialize(from, to, opts = {})
		@from = from
		@to = to
		self.set_default
		opts.each do |data|
			self.send("#{data.first}=", data.last)
		end if opts != {} && opts.class == Hash
		self.check_values
	end
	
	#ダメージオブジェクト用のデフォルト値の設定
	def set_default
	
		#ダメージ値
		@damage = 0
		
		#攻撃/防御によって与えられるダメージ基準値
		@reference = {
			attack: 0,
			deffense: 0,
			rate: 1.0
		}
		
		#ダメージ属性
		@attribute = {
			send_type: "NONE",		#攻撃側の属性
			receive_type: "NONE",	#防御側の属性
			rate: 1.0					#属性によるダメージ補正
		}
		
		#クリティカル関連の数値
		@critical = {
			decision: false,					#trueならクリティカル発生、falseならクリティカル発生せず
			probability: 0, 					#このダメージが発生した際のクリティカル発生率
			force_critical: false, 			#強制クリティカルがONになっているかどうか
			rate: Default_critical_rate	#クリティカルによるダメージへの寄与率
		} 
		
		#ダメージの決定に使用された特効値
		@amplify = {
			type: "NONE",			#特効の種類(スキルに付与された特効なのかとか、特殊能力による特効なのかとか)
			target: "NONE",		#特効対象となる相手
			rate: 1.0				#特効倍率
		}
		
		#ダメージの決定に使用されたスキルの種類。
		#配列での取得であることに注意。
		#ex1.アイテムによる魔法攻撃の場合には@skill_type = [:item, :magic]
		#ex2.通常攻撃によるダメージの場合には@skill_type = [:attack]
		@skill_type = []
		
		#ダメージ値が固定か変動するかの設定
		@random = {
			decision: true,			#trueならダメージに乱数が反映される
			rate: 1.0, 					#ダメージに反映されている乱数の値
		}
		
		#攻撃側で発生しているスキル一覧
		@send_skills =[]

		#防御側で発生しているスキル一覧
		@receive_skills =[]
		
		#ダメージに紐付けられたスキル名
		@skill_name = "スキル名なし"
	end
	
	#不正なデータがあった場合には強制的に安全な状態に修正
	def check_values
		@damage = 0 if @damage.class != Fixnum && @damage.class != Float
		@reference = {attack: 0,deffense: 0,rate: 1.0} if @reference.class != Hash
		@attribute = {send_type: "NONE", receive_type: "NONE", rate: 1.0} if @attribute.class != Hash
		@critical = {decision: false, probability: 0, force_critical: false, rate: Default_critical_rate} if @critical.class != Hash
		@amplify = {type: "NONE", target: "NONE", rate: 1.0} if @amplify.class != Hash
		@skill_type = [] if @skill_type.class != Array
		@random = {decision: true, rate: 1.0} if @random.class != Hash
		@send_skills = [] if @send_skills.class != Array
		@receive_skills = [] if @receive_skills.class != Array
		@skill_name = "スキル名なし" if @skill_name.class != String
	end
	
	# ダメージのデータをハッシュとして取り出せるようにする
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
