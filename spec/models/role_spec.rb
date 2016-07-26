require 'rails_helper'

RSpec.describe Role, type: :model do
  let(:admin) { Role.find_by(name: "administrator") }
  let(:moderator) { Role.find_by(name: "moderator") }
  let(:default) { Role.find_by(name: "default") }
  let(:banned) { Role.find_by(name: "banned") }
  describe '#get_permissions' do
    it 'should return an array with values for the appropriate role' do
      expect(admin.get_permissions).to_not be_empty
      expect(moderator.get_permissions).to_not be_empty
      expect(default.get_permissions).to_not be_empty
      expect(banned.get_permissions).to be_empty
    end
  end

  describe '#has_permission?' do
    it 'should return true or false for the specified permission' do
      perms = admin.get_permissions
      expect(admin.has_permission? perms[0] ).to be(true)
      expect(banned.has_permission? perms[0] ).to be(false)
    end
  end
end
