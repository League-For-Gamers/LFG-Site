class Post < ActiveRecord::Base
  include Postable
  belongs_to :user
  belongs_to :group
  belongs_to :parent, class_name: 'Post', foreign_key: :parent_id, counter_cache: :children_count
  has_many :children, class_name: 'Post', foreign_key: :parent_id, dependent: :destroy

  # TODO: Maximum of 5 stickied posts.

  validates :body, length: { maximum: 512 }
  validates :user, :body, presence: true
  has_many :bans, -> { order 'end_date DESC'}

  before_validation do
    remove_zalgo! self.body
  end

  before_destroy do
    self.bans.each do |ban|
      ban.post = nil
      ban.save
    end
  end
end
