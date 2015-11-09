require 'rails_helper'

RSpec.describe ApplicationHelper, :type => :helper do
  let(:bobby) { FactoryGirl.create(:user) }
  describe '#logged_in?' do
    it 'returns true when logged in' do
      session[:user] = bobby.id
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
  
  describe '#replace_urls' do
    it 'should parse URLs and return a valid HTML link' do
      body = "https://i.imgur.com/Qe6xws5.jpg"
      # This can probably be remade better.
      expect(helper.replace_urls(body)).to_not eq(body)
      expect(helper.replace_urls(body)).to eq("<a href=\"https://i.imgur.com/Qe6xws5.jpg\">https://i.imgur.com/Qe6xws5.jpg</a>")
    end

    it 'should escape HTML hidden in URLs' do
      body = 'http://i.imgur.com/<script>alert("wee-woo");</script>'
      expect(helper.replace_urls(body)).to include("&lt;script&gt;alert(\"wee-woo\");&lt;/script&gt;")
    end

    it 'should escape raw HTML' do
      body = "http://imgur.com\n<script>alert(\"wee-woo\");</script>"
      expect(helper.replace_urls(body)).to include("&lt;script&gt;")
    end
  end
end
