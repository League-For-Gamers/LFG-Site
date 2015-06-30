require 'rails_helper'

RSpec.describe Game, :type => :model do
  let(:skill) {FactoryGirl.create(:skill)}
  it "cannot have duplicates" do
    skill1 = FactoryGirl.build(:skill, category: skill.category, confidence: skill.confidence, user: skill.user)
    expect(skill1).to_not be_valid
  end

  it "cannot have a confidence out of the range 1..10" do
    skill = FactoryGirl.build(:skill, confidence: 11)
    expect(skill).to_not be_valid
  end
end
