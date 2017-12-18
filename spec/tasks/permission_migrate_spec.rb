require 'rails_helper'
require 'rake'

RSpec.describe "permission_migrate", type: :rake do
  let(:bobby) { FactoryBot.create(:user) }
  let(:wingar) { FactoryBot.create(:user, username: "wingar", display_name: "dick", email: "dicks@dicks.dicks", email_confirm: "dicks@dicks.dicks") }
  describe "#set_default_user_role" do
    before do
      Rake::Task.define_task(:environment)
    end
    
    it "should set users role from nil to default" do
      bobby.role = nil
      bobby.save
      expect(User.find(bobby.id).role).to eq(nil)
      Rake::Task["db:set_default_user_role"].invoke
      expect(User.find(bobby.id).role).to be_present
      expect(User.find(bobby.id).role.name).to eq("default")
    end
  end

  describe "#set_banner_id_to_wingar" do
    before do
      Rake::Task.define_task(:environment)
      wingar.valid?
    end
    
    it 'should set the banner id of a ban to wingar' do
      b = Ban.new(user: bobby, end_date: Time.now, role_id: 2)
      b.save(validate: false)
      expect(Ban.find(b.id).banner_id).to be_blank
      Rake::Task["db:set_banner_id_to_wingar"].invoke
      expect(Ban.find(b.id).banner_id).to eq(wingar.id)
    end
  end

  describe "#set_ban_duration_string" do
    before do
      Rake::Task.define_task(:environment)
    end

    it 'should set the duration_string of the ban' do
      b = Ban.create(user: bobby, end_date: Time.now, role_id: 2, banner: wingar)
      b.save
      expect(Ban.find(b.id).duration_string).to be_blank
      Rake::Task["db:set_ban_duration_string"].invoke
      expect(Ban.find(b.id).duration_string).to_not be_blank
    end
  end

  it 'getting rid of stupid coverage bugs' do
    DevelopmentProfiler
  end
end