module MyEnum
  def self.included(base)
    base.extend ClassMethods
  end

  module ClassMethods
    def enum(definitions)
      key = definitions.keys.first
      value = definitions.values.first

      # valueが配列ならばハッシュにする
      value = value.map.with_index{ |v, i| [v, i] }.to_h if value.class == Array
      
      # keyと同じ名前のインスタンス変数を定義する
      self.class_eval{ instance_variable_set('@' + key.to_s, nil) }

      # keyと同じ名前のメソッドを定義する
      self.class_eval{ define_method(key){ value.key(instance_variable_get('@' + key.to_s)) } }
      
      # keyと同じ名前の特異メソッドを定義する
      self.class_eval{ self.define_singleton_method(key){ instance_variable_get('@' + key.to_s) } }
      
      value.keys.each do |value_key|
        self.class_eval do
          define_method(value_key.to_s + '!'){ instance_variable_set('@' + key.to_s, value[value_key]) } # 値の変更
          define_method(value_key.to_s + '?'){ instance_variable_get('@' + key.to_s) == value[value_key] } # 値の検査
          define_singleton_method(value_key.to_s){ $database.select{ |data| data.send(value_key.to_s + '?') } } # 条件に合うインスタンスの抽出
          define_singleton_method('not_' + value_key.to_s){ $database.reject{ |data| data.send(value_key.to_s + '?') } } # 条件に合わないインスタンスの抽出
        end
      end
    end
  end
end
