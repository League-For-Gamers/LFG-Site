require 'rails_helper'

RSpec.describe ApplicationHelper, :type => :helper do
  let(:bobby) { FactoryGirl.create(:user) }
  let(:admin_bobby) { FactoryGirl.create(:administrator_user)}
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
      expect(helper.replace_urls(body)).to eq("<a data-no-turbolink=\"true\" href=\"https://i.imgur.com/Qe6xws5.jpg\">https://i.imgur.com/Qe6xws5.jpg</a>")
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

  describe '#ban_string' do
    let(:group) { FactoryGirl.create(:group)}
    let(:membership) { FactoryGirl.create(:group_membership, user: bobby, group: group) }
    it 'should return a string containing information about the ban' do
      # Test bans
      membership.ban("dick", 1.week.from_now, admin_bobby)
      ban = Ban.where(user: bobby, group: group).last
      ban_str = helper.ban_string(ban)
      expect(ban_str).to include("banned")
      expect(ban_str).to include("for")
      expect(ban_str).to include(ban.reason)

      # Test permabans
      membership.ban("dick", nil, admin_bobby)
      ban = Ban.where(user: bobby, group: group).last
      ban_str = helper.ban_string(ban)
      expect(ban_str).to include("banned")
      expect(ban_str).to include("end of time")
      expect(ban_str).to include(ban.reason)

      # Test unbans
      membership.unban("dock", admin_bobby)
      ban = Ban.where(user: bobby, group: group).last
      ban_str = helper.ban_string(ban)
      expect(ban_str).to include("unbanned")
      expect(ban_str).to_not include("for")
      expect(ban_str).to include(ban.reason)
    end
  end

  describe '#number_to_cardinal' do
    it 'should return expected strings for all cardinalizations' do
      # A LOT of tests in one!
      nums = [[547, "547"],[5479, "5,479"],[54797, "54.80K"],[547976, "547.98K"],
        [5479760, "5.48M"],[54797609, "54.80M"],[547976096, "547.98M"],
        [5479760962, "5.48B"],[54797609628, "54.80B"],[547976096281, "547.98B"],
        [5479760962810, "5.48T"],[54797609628108, "54.80T"],[547976096281089, "547.98T"],
        [5479760962810899, "5.48P"],[54797609628108994, "54.80P"],[547976096281089944, "547.98P"],
        [5479760962810899440, "5.48E"],[54797609628108994402, "54.80E"],[547976096281089944028, "547.98E"],
        [5479760962810899440285, "5.48Z"],[54797609628108994402857, "54.80Z"],[547976096281089944028570, "547.98Z"],
        [5479760962810899440285702, "5.48Y"],[54797609628108994402857021, "54.80Y"],[547976096281089944028570217, "547.98Y"],
        [5479760962810899440285702176, "5479.76Y"]]
      nums.each do |n|
        expect(helper.number_to_cardinal(n[0])).to eq(n[1])
      end
    end
  end
end
