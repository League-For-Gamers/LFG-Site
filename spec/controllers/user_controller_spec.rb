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
      expect(assigns(:current_user).errors).to be_empty
      expect(bobby.games).to include(Game.find_by name: game)
    end

    it "removes a game from the users list" do
      bobby.games << FactoryGirl.create(:game, name: "newgame1")
      bobby.games << FactoryGirl.create(:game, name: "newgame2")
      patch :update, user: { games: { "0" => {id: Game.find_by(name: "newgame1").id, name: "newgame1"}, "1" => {id: Game.find_by(name: "newgame2").id, name: ""}} }
      expect(User.find(bobby.id).games).to_not include(Game.find_by(name: "newgame2"))
      expect(assigns(:current_user).errors).to be_empty
      expect(response).to redirect_to("/account")
    end

    it "adds a skill to the users list" do
      patch :update, user: { skills_attributes: {"0" => {id: nil, category: :code, confidence: 7} }, games: {"0" => {name: "fdsf"}}}
      expect(response).to redirect_to("/account")
      expect(assigns(:current_user).errors).to be_empty
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

    it "successfully adds a tag" do
      patch :update, user: {tags: bobby.tags.map(&:name).join(", ") + ", new_tag" }
      expect(User.find(bobby.id).tags).to include(Tag.find_by(name: "new_tag", user: bobby))
      expect(assigns(:current_user).errors).to be_empty
      expect(response).to redirect_to("/account")
    end

    it "throws an error on an invalid tag entry" do
      patch :update, user: {tags: "new tag" }
      expect(assigns(:current_user).errors).to_not be_empty
      expect(response).to_not redirect_to("/account")
    end

    it "successfully removes a tag" do
      old_tags = bobby.tags
      bobby.tags << FactoryGirl.create(:tag, user: bobby)
      patch :update, user: {tags: old_tags.map(&:name).join(", ") }
      expect(User.find(bobby.id).tags).to eq(old_tags)
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

  describe "GET /search" do
    context "without any queries or filter" do
      it "should not search for any results" do
        get :search
        expect(assigns(:results)).to_not be_present
      end
    end

    context "with queries but no filter" do
      it "should return a result with a user when querying for their name" do
        get :search, query: bobby.display_name
        expect(assigns(:results)).to include(bobby)
      end
      it "should return a result with a user when querying for a tag in their collection" do
        bobby.tags << FactoryGirl.create(:tag, name: "likes_tables", user: bobby)
        get :search, query: "likes_tables"
        expect(assigns(:results)).to include(bobby)
      end
    end

    context "with queries and a filter" do
      it "should return a user when querying for their name and a matching skill" do
        bobby.skills << FactoryGirl.create(:skill, category: :code, user: bobby)
        get :search, query: "bobby", filter: "code"
        expect(assigns(:results)).to include(bobby)
      end
      it "should not return a user when querying for their name and a skill they dont have" do
        bobby.skills << FactoryGirl.create(:skill, category: :code, user: bobby)
        get :search, query: "bobby", filter: "writing"
        expect(assigns(:results)).to_not include(bobby)
      end
    end

    context "with no queries and a filter" do
      it "should return a user with a matching skill" do
        bobby.skills << FactoryGirl.create(:skill, category: :code, user: bobby)
        get :search, filter: "code"
        expect(assigns(:results)).to include(bobby)
      end
      it "should not return a user with a skill they dont have" do
        bobby.skills << FactoryGirl.create(:skill, category: :code, user: bobby)
        get :search, filter: "writing"
        expect(assigns(:results)).to_not include(bobby)
      end
    end
  end
end
