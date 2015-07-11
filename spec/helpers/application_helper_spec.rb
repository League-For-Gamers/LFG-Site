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

  describe '#full_urlify' do
    it 'should create a valid, full URI from an incomplete one' do
      url = "leagueforgamers.com"
      expect(helper.full_urlify(url)).to eq("http://#{url}")
    end

    it 'should not add a new http protocol scheme to a url that already has one' do
      url = "http://leagueforgamers.com"
      expect(helper.full_urlify(url)).to eq(url)
    end
  end

  describe '#reverse_urlify' do
    it 'should remove protocol scheme from the URL' do
      url = "http://leagueforgamers.com"
      expect(helper.reverse_urlify(url)).to eq("leagueforgamers.com")
    end
  end
end
