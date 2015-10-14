require 'rails_helper'

RSpec.describe Group, type: :model do
  let(:group) { FactoryGirl.create(:group) }
  it "has a valid factory" do
    expect(group).to be_valid
    expect(group.slug).to_not be_empty
  end
end
