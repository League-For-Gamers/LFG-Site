require 'rails_helper'
require 'rake'

RSpec.describe "permission_migrate", type: :rake do
  describe "#set_default_user_role" do
    before do
      Rake::Task.define_task(:environment)
    end
    let(:bobby) { FactoryGirl.create(:user) }
    it "should set users role from nil to default" do
      bobby.role = nil
      bobby.save
      expect(User.find(bobby.id).role).to eq(nil)
      Rake::Task["db:set_default_user_role"].invoke
      expect(User.find(bobby.id).role).to be_present
      expect(User.find(bobby.id).role.name).to eq("default")
    end
  end
end