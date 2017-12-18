require 'rails_helper'

RSpec.describe Skill, :type => :model do
  let(:skill) {FactoryBot.create(:skill)}
  it "cannot have duplicates" do
    skill1 = FactoryBot.build(:skill, category: skill.category, confidence: skill.confidence, user: skill.user)
    expect(skill1).to_not be_valid
  end

  it "cannot have a confidence out of the range 1..10" do
    skill = FactoryBot.build(:skill, confidence: 11)
    expect(skill).to_not be_valid
  end
end
