require 'rails_helper'

RSpec.describe Post, type: :model do
  let(:post) { FactoryGirl.create(:post) }
  it "has a valid factory" do
    expect(post).to be_valid
  end
  it "fails to validate on a post with a body larger than 500 characters" do
    body = ""
    300.times { body << "test test "}
    post = FactoryGirl.build(:post, body: body)
    expect(post).to_not be_valid
  end
end
