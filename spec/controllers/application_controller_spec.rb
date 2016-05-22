require 'rails_helper'

RSpec.describe ApplicationController, :type => :controller do
  controller do
    def index
      render nothing: true
    end
  end
  let(:bobby) { FactoryGirl.create(:user) }
  let(:admin_bobby) { FactoryGirl.create(:administrator_user)}
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
          bobby.ban("dick", 1.week.ago, admin_bobby)
          expect(User.find(bobby.id).role.name).to eq("banned")
          controller.send(:set_current_user)
          expect(assigns(:current_user).role.name).to_not eq("banned")
        end
        it 'does not unban permabanned users' do
          bobby.ban("dick", nil, admin_bobby)
          expect(User.find(bobby.id).role.name).to eq("banned")
          controller.send(:set_current_user)
          expect(assigns(:current_user).role.name).to eq("banned") 
        end
        it 'sets @ban variable when user is banned' do
          bobby.ban("dick", nil, admin_bobby)
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
      it 'remember_user successfully returns a HMAC cookie for login' do
        controller.send(:remember_user, bobby, request)
        expect(cookies[:remember]).to_not be_nil
      end

      context 'login_from_token' do
        it 'does nothing if there is no login cookie' do
          controller.send(:login_from_token)
          expect(session[:user]).to be_nil
        end

        it 'will log in the user with a valid cookie' do
          controller.send(:remember_user, bobby, request)
          expect(cookies[:remember]).to_not be_nil
          get :index
          expect(session[:user]).to_not be_nil
          expect(session[:user]).to eq(bobby.id)
          expect(response).to redirect_to(root_url + "anonymous")
        end

        it 'will reject and delete an invalid cookie' do
          t = 4.weeks.ago
          auth = "#{bobby.id},#{request.ip},#{t.yday}#{t.year}"
          hmac = OpenSSL::HMAC.hexdigest(OpenSSL::Digest::SHA256.new, ENV['SECRET_TOKEN'], auth)
          cookies[:remember] = { value: "#{bobby.id}:#{hmac}", expires: 3.weeks.from_now }
          get :index
          expect(session[:user]).to be_nil
          expect(session[:user]).to_not eq(bobby.id)
          expect(cookies[:remember]).to be_nil
        end
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
