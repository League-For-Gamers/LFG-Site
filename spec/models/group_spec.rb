require 'rails_helper'

RSpec.describe Group, type: :model do
  let(:group) { FactoryBot.create(:group) }
  let(:bobby) { FactoryBot.create(:user) }
  before do
    FactoryBot.create(:group_membership, user: bobby, group: group)
  end
  it "has a valid factory" do
    expect(group).to be_valid
    expect(group.slug).to_not be_empty
    expect(bobby).to be_valid
    expect(bobby.groups).to include(group)
  end
end
