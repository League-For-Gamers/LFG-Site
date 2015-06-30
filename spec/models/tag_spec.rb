require 'rails_helper'

RSpec.describe Tag, :type => :model do
  let(:tag) {FactoryGirl.create(:tag)}
  it "cannot have duplicates" do
    tag1 = FactoryGirl.build(:tag, name: tag.name, user: tag.user)
    expect(tag1).to_not be_valid
  end

  it "cannot have name longer than 50 characters" do
    skill = FactoryGirl.build(:tag, name: ("a".."ba").to_a.join) # creates 80 characters
    expect(skill).to_not be_valid
  end

  it "cannot have name invalid characters in name" do
    skill = FactoryGirl.build(:tag, name: "hash tag!!@@")
    expect(skill).to_not be_valid
  end
end

