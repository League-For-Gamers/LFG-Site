require 'rails_helper'

RSpec.describe ApplicationController, :type => :controller do
  let(:bobby) { FactoryGirl.create(:user) }
  describe "user login helpers" do
    context "with user logged in" do
      before do
        session[:user] = bobby.id
      end

      it 'logged_in? returns true' do
        expect(controller.send(:logged_in?)).to eq(true)
      end

      context "#set_current_user" do
        it 'sets @current_user' do
          controller.send(:set_current_user)
          expect(assigns(:current_user).username).to eq(bobby.username)
        end
        it 'unbans banned users when their date is passed' do
          bobby.ban("dick", 1.week.ago)
          expect(User.find(bobby.id).role.name).to eq("banned")
          controller.send(:set_current_user)
          expect(assigns(:current_user).role.name).to_not eq("banned")
        end
        it 'does not unban permabanned users' do
          bobby.ban("dick", nil)
          expect(User.find(bobby.id).role.name).to eq("banned")
          controller.send(:set_current_user)
          expect(assigns(:current_user).role.name).to eq("banned") 
        end
        it 'sets @ban variable when user is banned' do
          bobby.ban("dick", nil)
          expect(User.find(bobby.id).role.name).to eq("banned")
          controller.send(:set_current_user)
          expect(assigns(:ban)).to be_present
        end
      end

      it '#logout_user successfully removes session' do
        controller.send(:logout_user)
        expect(controller.send(:logged_in?)).to eq(false)
      end
    end
    context "with user not logged in" do
      it 'logged_in? returns false' do
        expect(controller.send(:logged_in?)).to eq(false)
      end

      it 'login_user successfully sets user session' do
        controller.send(:login_user, bobby)
        expect(controller.send(:logged_in?)).to eq(true)
      end
    end
  end

  describe "not_found errors" do
    it "should raise an exception" do
      expect { controller.send(:not_found) }.to raise_error("Not Found")
    end
  end

  describe "set_title" do
    it "should set the @title variable" do
      controller.send(:set_title, "Test")
      expect(assigns(:title)).to eq("Test — League For Gamers")
    end
  end
end
