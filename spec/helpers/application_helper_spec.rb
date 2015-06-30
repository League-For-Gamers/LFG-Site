require 'rails_helper'

RSpec.describe ApplicationHelper, :type => :helper do
  let(:bobby) { FactoryGirl.create(:user) }
  describe '#logged_in?' do
    it 'returns true when logged in' do
      session[:user] = {id: 5}
      expect(helper.logged_in?).to eq(true)
    end
  end

  describe '#display_name' do
    it 'should display the user display_name' do
      expect(helper.display_name(bobby)).to eq(bobby.display_name)
    end
  end
end
