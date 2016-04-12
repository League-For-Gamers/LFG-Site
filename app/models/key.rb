class Key < ActiveRecord::Base
  enum key_type: [:public_key, :private_key]
  belongs_to :user
  belongs_to :group
  belongs_to :parent, class_name: 'Key'
  has_many :children, class_name: 'Key', foreign_key: 'parent_id'
end
