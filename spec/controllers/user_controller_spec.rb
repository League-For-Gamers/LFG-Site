require 'rails_helper'

RSpec.describe UserController, :type => :controller do
  let(:bobby) { FactoryGirl.create(:user) }

  describe "GET /login" do
    it "redirects logged in users to root_url" do
      session[:user] = bobby.id
      get :login
      expect(response).to redirect_to(root_url)
    end
  end

  describe "POST /login" do
    it "creates a session for the user" do
      post :login_check, username: bobby.username, password: bobby.password
      expect(session[:user]).to eq(bobby.id)
      expect(response).to redirect_to(root_url)
    end
    it "displays an error for invalid credentials" do
      post :login_check, username: bobby.username, password: "invalid password"
      expect(session[:user]).to_not eq(bobby.id)
      expect(flash[:alert]).to be_present
    end
  end

  describe "GET /logout" do
    it "destroys the session for the user" do
      session[:user] = bobby.id
      get :logout
      expect(session[:user]).to_not be_present
      expect(flash[:notice]).to be_present
      expect(response).to redirect_to(root_url)
    end
  end

  describe "GET /signup" do
    it "creates @user for view" do
      get :signup
      expect(assigns(:user)).to be_present
    end
  end

  describe "POST /signup" do
    it "creates a new user" do
      pass = "a really great password!"
      post :create, user: FactoryGirl.attributes_for(:user, username: "new_user", password: pass, password_confirmation: pass, email: "an_exciting@user.com")
      expect(session[:user]).to be_present
      expect(flash[:notice]).to be_present
      expect(response).to redirect_to("/user/new_user")
    end

    it "returns an error on an invalid entry" do
      post :create, user: FactoryGirl.attributes_for(:user, username: "new user", email: "invalid email")
      expect(session[:user]).to_not be_present
    end
  end

  describe "GET /account" do
    context "without being logged in" do
      it "redirects users to root_url with a warning" do
        get :my_account
        expect(response).to redirect_to(root_url)
      end
    end
    context "while being logged in" do
      before do
        session[:user] = bobby.id
      end
      it "sets @games" do
        get :my_account
        expect(assigns(:games)).to be_present
      end
    end
  end

  describe "PATCH /account" do
    before do
      session[:user] = bobby.id
    end

    it "adds a new game to the users list" do
      game = "Starcraft III"
      patch :update, user: { games: { "0" => {name: game} }}
      expect(response).to redirect_to("/account")
      expect(bobby.games).to include(Game.find_by name: game)
    end

    it "adds a skill to the users list" do
      patch :update, user: { skills_attributes: {"0" => {id: nil, category: :code, confidence: 7} }, games: {"0" => {name: "fdsf"}}}
      expect(response).to redirect_to("/account")
      expect(bobby.skills.map {|x| [x.category, x.confidence]}).to include(["code", 7])
    end
    it "removes a skill from the users list" do
      skill = Skill.new(category: :code, confidence: 7) # Should probably use factory girl
      bobby.skills << skill
      patch :update, user: { skills_attributes: {"0" => {id: skill.id, category: "", confidence: skill.confidence} }}
      expect(response).to redirect_to("/account")
      expect(assigns(:current_user).errors).to be_empty
      expect(assigns(:current_user).skills.length).to eq(0) 
    end

    it "throws a errors with mismatched passwords" do
      patch :update, user: {old_password: "not bobbys password", password: "newpass", password_confirmation: "newpass"}
      expect(User.find(bobby.id).password_digest).to eq(bobby.password_digest)
      expect(assigns(:current_user).errors).to_not be_empty
      expect(response).to_not redirect_to("/account")
    end

    it "successfully changes the password" do
      patch :update, user: {old_password: bobby.password, password: "newpass", password_confirmation: "newpass"}
      expect(User.find(bobby.id).password_digest).to_not eq(bobby.password_digest)
      expect(assigns(:current_user).errors).to be_empty
      expect(response).to redirect_to("/account")
    end
  end

  describe "GET /user/:id" do
    it "sets @user" do
      get :show, id: bobby.username
      expect(assigns(:user)).to eq(bobby)
    end
    it "renders an error for an invalid id" do
      get :show, id: 995325943589
      expect(response).to render_template('shared/not_found')
      expect(response.status).to eq(404)
    end
  end
end
