class Post < ActiveRecord::Base
  belongs_to :user

  validates :body, length: { maximum: 512 }

  # Remove Zalgo from display names.
  # It's not perfect, but it should do just fine, it's threshold based 
  # So it shouldn't catch smaller fancy-text things.
  before_validation do
    self.body = self.body.gsub(/[\u0300-\u036f\u0489]/, '') if self.body =~ /[\u0300-\u036f\u0489]{3}/
  end
end
