class Post < ApplicationRecord
  include Postable
  belongs_to :user
  belongs_to :group, required: false
  belongs_to :parent, class_name: 'Post', foreign_key: :parent_id, counter_cache: :children_count, required: false
  has_many :children, class_name: 'Post', foreign_key: :parent_id, dependent: :destroy

  attr_accessor :enable_save_callbacks

  # TODO: Maximum of 5 stickied posts.

  validates :body, length: { maximum: 512 }
  validates :user, :body, presence: true
  has_many :bans, -> { order 'end_date DESC'}

  def enable_save_callbacks?
    enable_save_callbacks != false
  end

  before_validation do
    remove_zalgo! self.body
  end

  after_create do
    GetOpengraphTagsJob.perform_later(self) if enable_save_callbacks?
  end

  after_update do
    GetOpengraphTagsJob.perform_later(self) if enable_save_callbacks?
  end

  before_destroy do
    self.bans.each do |ban|
      ban.post = nil
      ban.save
    end
  end
end
