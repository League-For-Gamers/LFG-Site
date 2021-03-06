require 'rails_helper'

RSpec.describe UserController, :type => :controller do
  let(:bobby) { FactoryBot.create(:user) }

  describe "GET /login" do
    it "redirects logged in users to root_url" do
      session[:user] = bobby.id
      get :login
      expect(response).to redirect_to(root_url)
    end

    it "renders the login template when not logged in" do
      get :login
      expect(response).to render_template(:login)
    end

    it "will log in the user with a valid cookie" do
      post :login_check, params: { username: bobby.username, password: bobby.password, remember: true }
      expect(session[:user]).to eq(bobby.id)
      expect(cookies[:remember]).to_not be_nil
      get :login
      expect(response).to redirect_to(root_url)
    end
  end

  describe "POST /login" do
    context 'creates a session for the user' do
      it "without remember login set" do
        post :login_check, params: { username: bobby.username, password: bobby.password }
        expect(session[:user]).to eq(bobby.id)
        #expect(response).to redirect_to(root_url)
      end
      it "and ensures a remember cookie is set when requested" do
        post :login_check, params: { username: bobby.username, password: bobby.password, remember: true }
        expect(session[:user]).to eq(bobby.id)
        expect(cookies[:remember]).to_not be_nil
      end
    end
    it "displays an error for invalid credentials" do
      post :login_check, params: { username: bobby.username, password: "invalid password" }
      expect(session[:user]).to_not eq(bobby.id)
      expect(flash[:warning]).to be_present
    end
  end

  describe "GET /logout" do
    it "destroys the session for the user" do
      session[:user] = bobby.id
      get :logout
      expect(session[:user]).to_not be_present
      expect(flash[:info]).to be_present
      expect(response).to redirect_to('/signup')
    end
  end

  describe "GET /user/forgot_password" do
    context "when logged in" do
      before do
        session[:user] = bobby.id
      end
      it "should redirect to root_url" do
        get :forgot_password
        expect(response).to redirect_to(root_url)
      end
    end
  end

  describe "POST /user/forgot_password" do
    context "when logged in" do
      before do
        session[:user] = bobby.id
      end
      it "should redirect to root_url" do
        post :forgot_password_check
        expect(response).to redirect_to(root_url)
      end
    end
    context "when not logged in" do
      it "should generate a verification_digest if user is found" do
        post :forgot_password_check, params: { email: bobby.decrypted_email }
        expect(User.find(bobby.id).verification_digest).to be_present
      end
      it "should not generate a verification_digest when a user is not found" do
        post :forgot_password_check, params: { email: "blah@blah.blah" }
        expect(User.find(bobby.id).verification_digest).to_not be_present
      end
    end
  end

  describe "GET /user/forgot_password/:activation_id" do
    it "should gracefully fail when passed an invalid activation id" do
      get :reset_password, params: { activation_id: "junk" }
      expect(response).to render_template(:reset_password_invalid)
    end
    it "should render the main template when passed a valid activation id" do
      bobby.generate_verification_digest
      get :reset_password, params: { activation_id: bobby.verification_digest }
      expect(response).to render_template(:reset_password)
      expect(assigns(:user)).to be_present
    end
  end

  describe "POST /user/forgot_password/:activation_id" do
    it "should fail gracefully when passed an invalid activation id" do
      post :reset_password_check, params: { activation_id: "junk" }
      expect(User.find(bobby.id).password_digest).to eq(bobby.password_digest)
      expect(response).to redirect_to('/signup')
      expect(flash[:info]).to be_present
    end
    it "should change the users password and set the verification_digest to invalid" do
      bobby.generate_verification_digest
      post :reset_password_check, params: { activation_id: bobby.verification_digest, password: 'new password' }
      expect(User.find(bobby.id).password_digest).to_not eq(bobby.password_digest)
      expect(User.find(bobby.id).verification_active.to_i).to be < Time.now.to_i
    end
  end

  describe "GET /signup" do
    context "when not logged in" do
      it "shows the signup page" do
        get :signup
        expect(response).to render_template(:signup)
      end
    end
    context "when logged in" do
      before do
        session[:user] = bobby.id
      end

      it "redirects to root_url" do
        get :signup
        expect(response).to redirect_to(root_url)
      end
    end
  end

  describe "POST /signup" do
    it "creates a new user" do
      pass = "a really great password!"
      email = "an_exciting@user.com"
      post :create, params: { user: FactoryBot.attributes_for(:user, username: "new_user", password: pass, email: email, email_confirm: email) }
      expect(session[:user]).to be_present
      expect(flash[:notice]).to be_present
      expect(response).to redirect_to("/account")
    end

    it "returns an error on an invalid entry" do
      post :create, params: { user: FactoryBot.attributes_for(:user, username: "new user", email: "invalid email") }
      expect(session[:user]).to_not be_present
    end
  end

  describe "GET /account" do
    context "without being logged in" do
      it "redirects users to /signup with a warning" do
        get :my_account
        expect(response).to redirect_to('/signup')
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
      patch :update, params: { user: { games: { "0" => {name: game} }} }
      expect(response).to redirect_to("/account")
      expect(assigns(:current_user).errors).to be_empty
      expect(bobby.games).to include(Game.find_by name: game)
    end

    it "removes a game from the users list" do
      bobby.games << FactoryBot.create(:game, name: "newgame1")
      bobby.games << FactoryBot.create(:game, name: "newgame2")
      patch :update, params: { user: { games: { "0" => {id: Game.find_by(name: "newgame1").id, name: "newgame1"}, "1" => {id: Game.find_by(name: "newgame2").id, name: ""}} } }
      expect(User.find(bobby.id).games).to_not include(Game.find_by(name: "newgame2"))
      expect(assigns(:current_user).errors).to be_empty
      expect(response).to redirect_to("/account")
    end

    it "adds a skill to the users list" do
      patch :update, params: { user: { skills_attributes: {"0" => {id: nil, category: :writing, confidence: 7} }, games: {"0" => {name: "fdsf"}}} }
      expect(response).to redirect_to("/account")
      expect(assigns(:current_user).errors).to be_empty
      expect(bobby.skills.map {|x| [x.category, x.confidence]}).to include(["writing", 7])
    end

    it "removes a skill from the users list" do
      skill = Skill.new(category: :writing, confidence: 7) # Should probably use factory girl
      bobby.skills << skill
      patch :update, params: { user: { skills_attributes: {"0" => {id: skill.id, category: "", confidence: skill.confidence} }} }
      expect(response).to redirect_to("/account")
      expect(assigns(:current_user).errors).to be_empty
      expect(assigns(:current_user).skills.length).to eq(0) 
    end

    describe "more complicated skill management details" do
      it "ignores empty lines that were created on the client side" do
        skills_attributes = {
                              "0"             => {"id"=>"", "category"=>"web_programming", "confidence"=>"2", "note"=>"", "test"=>"test"},
                              "1440040946004" => {"id"=>"", "category"=>"", "confidence"=>"4", "note"=>"", "test"=>"test"},
                              "1440040947354" => {"id"=>"", "category"=>"voice_acting/directing", "confidence"=>"8", "note"=>"", "test"=>"test"},
                              "1440040948106" => {"id"=>"", "category"=>"", "confidence"=>"6", "note"=>"", "test"=>"test"}
                            }
        patch :update, params: { user: { skills_attributes: skills_attributes } }
        results = bobby.skills.map {|x| [x.category, x.confidence]}
        expect(results.count).to eql(2)
        expect(results).to include(["web_programming", 2])
        expect(results).to include(["voice_acting/directing", 8])
      end
    end

    it "throws a errors with mismatched passwords" do
      patch :update, params: { user: {old_password: "not bobbys password", password: "newpass", password_confirmation: "newpass"} }
      expect(User.find(bobby.id).password_digest).to eq(bobby.password_digest)
      expect(assigns(:current_user).errors).to_not be_empty
      expect(response).to_not redirect_to("/account")
    end

    it "successfully changes the password" do
      patch :update, params: { user: {old_password: bobby.password, password: "newpass", password_confirmation: "newpass"} }
      expect(User.find(bobby.id).password_digest).to_not eq(bobby.password_digest)
      expect(assigns(:current_user).errors).to be_empty
      expect(response).to redirect_to("/account")
    end

    it "successfully adds a tag" do
      patch :update, params: { user: {tags: bobby.tags.map(&:name).join(", ") + ", new_tag" } }
      expect(User.find(bobby.id).tags).to include(Tag.find_by(name: "new_tag", user: bobby))
      expect(assigns(:current_user).errors).to be_empty
      expect(response).to redirect_to("/account")
    end

    context "more detailed tag inputs" do

      it "successfully adds a tag, given many different white-space separators" do
        patch :update, params: { user: {tags: "apple,orange,   banana,  squash" } }
        expect(User.find(bobby.id).tags).to include(Tag.find_by(name: "apple", user: bobby))
        expect(User.find(bobby.id).tags).to include(Tag.find_by(name: "orange", user: bobby))
        expect(User.find(bobby.id).tags).to include(Tag.find_by(name: "banana", user: bobby))
        expect(User.find(bobby.id).tags).to include(Tag.find_by(name: "squash", user: bobby))
        expect(assigns(:current_user).errors).to be_empty
        expect(response).to redirect_to("/account")
      end

      it "successfully adds a tag, given extra space on the right" do
        patch :update, params: { user: {tags: "apple  " } }
        expect(User.find(bobby.id).tags).to include(Tag.find_by(name: "apple", user: bobby))
        expect(assigns(:current_user).errors).to be_empty
        expect(response).to redirect_to("/account")
      end

      it "ignores empty entries" do
        patch :update, params: { user: {tags: ",apple,,   ,orange," } }
        expect(User.find(bobby.id).tags.count).to eql(2)
        expect(User.find(bobby.id).tags).to include(Tag.find_by(name: "apple", user: bobby))
        expect(User.find(bobby.id).tags).to include(Tag.find_by(name: "orange", user: bobby))
        expect(assigns(:current_user).errors).to be_empty
        expect(response).to redirect_to("/account")
      end

      it "treats new lines as separators" do
        patch :update, params: { user: {tags: "\n\r\napple\n\n\r\n\r\rorange\r\r\r\r\n\n\n\n" } }
        expect(User.find(bobby.id).tags.count).to eql(2)
        expect(User.find(bobby.id).tags).to include(Tag.find_by(name: "apple", user: bobby))
        expect(User.find(bobby.id).tags).to include(Tag.find_by(name: "orange", user: bobby))
        expect(assigns(:current_user).errors).to be_empty
        expect(response).to redirect_to("/account")
      end

    end

    it "throws an error on an invalid tag entry" do
      patch :update, params: { user: {tags: "new tag!!!!" } }
      expect(assigns(:current_user).errors).to_not be_empty
      expect(response).to_not redirect_to("/account")
    end

    it "successfully removes a tag" do
      old_tags = bobby.tags
      bobby.tags << FactoryBot.create(:tag, user: bobby)
      patch :update, params: { user: {tags: old_tags.map(&:name).join(", ") } }
      expect(User.find(bobby.id).tags).to eq(old_tags)
      expect(assigns(:current_user).errors).to be_empty
      expect(response).to redirect_to("/account")
    end

    it "successfully clears all tags if tag input is empty" do
      old_tags = bobby.tags
      bobby.tags << FactoryBot.create(:tag, user: bobby)
      patch :update, params: { user: {tags: '' } }
      expect(User.find(bobby.id).tags).to be_empty
      expect(assigns(:current_user).errors).to be_empty
      expect(response).to redirect_to("/account")
    end

    it "successfully clears all tags if tag input is missing" do
      old_tags = bobby.tags
      bobby.tags << FactoryBot.create(:tag, user: bobby)
      patch :update, params: { user: {tags: nil } }
      expect(User.find(bobby.id).tags).to be_empty
      expect(assigns(:current_user).errors).to be_empty
      expect(response).to redirect_to("/account")
    end

    context "when changing the name of an entered game" do
      it "does not change the name of the game globally but creates a new entry" do
        bobby.games << FactoryBot.create(:game, name: "newgame1")
        bobby.games << FactoryBot.create(:game, name: "newgame2")
        game2 = Game.find_by(name: "newgame2")

        patch :update, params: { user: { games: { "0" => {id: Game.find_by(name: "newgame1").id, name: "newgame1"}, "1" => {id: game2.id, name: "newgame3"}} } }
        expect(User.find(bobby.id).games).to_not include(Game.find_by(name: "newgame2"))
        expect(game2.id).to_not eq(Game.find_by(name: "newgame3").id)
        expect(assigns(:current_user).errors).to be_empty
        expect(response).to redirect_to("/account")
      end
    end
  end

  describe "GET /user/:id" do
    it "sets @user" do
      get :show, params: { id: bobby.username }
      expect(assigns(:user)).to eq(bobby)
    end
    it "renders an error for an invalid id" do
      get :show, params: { id: 995325943589 }
      expect(response).to render_template('shared/not_found')
      expect(response.status).to eq(404)
    end
  end

  describe "GET /user/:id/follow" do
    let(:admin_bobby) { FactoryBot.create(:administrator_user)}
    context 'when not logged in' do
      it 'should result in a 403 error' do
        get :follow, params: { id: bobby.username }
        expect(response.status).to eq(403)
      end
    end
    context 'when logged in' do
      before do
        session[:user] = bobby.id
      end
      context 'when trying to follow yourself' do
        it 'should result in a 403 error' do
          get :follow, params: { id: bobby.username }
          expect(response.status).to eq(403)
        end
      end
      context 'when the current user is not already following user' do
        it 'should follow the user' do
          get :follow, params: { id: admin_bobby.username }
          expect(response).to redirect_to root_url
          expect(User.find(bobby.id).follows.map(&:following)).to include(admin_bobby)
          expect(User.find(admin_bobby.id).followers.map(&:user)).to include(bobby)
        end
      end
      context 'when the current user is already following user' do
        it 'should unfollow the user' do
          FactoryBot.create(:follow, user: bobby, following: admin_bobby)
          expect(User.find(bobby.id).follows.map(&:following)).to include(admin_bobby)
          expect(User.find(admin_bobby.id).followers.map(&:user)).to include(bobby)
          get :follow, params: { id: admin_bobby.username }
          expect(response).to redirect_to root_url
          expect(User.find(bobby.id).follows.map(&:following)).to_not include(admin_bobby)
          expect(User.find(admin_bobby.id).followers.map(&:user)).to_not include(bobby)
        end
      end
    end
  end

  describe "GET /search" do
    before do
      session[:user] = bobby.id
    end
    context "without any queries or filter" do
      it "should not search for any results" do
        get :search
        expect(assigns(:results)).to_not be_present
      end
    end

    context "with queries but no filter" do
      it "should return a result with a user when querying for their name" do
        get :search, params: { query: bobby.display_name }
        expect(assigns(:results)).to include(bobby)
      end
      it "should return a result with a user when querying for a tag in their collection" do
        bobby.tags << FactoryBot.create(:tag, name: "likes_tables", user: bobby)
        get :search, params: { query: "likes_tables" }
        expect(assigns(:results)).to include(bobby)
      end
    end

    context "with queries and a filter" do
      it "should return a user when querying for their name and a matching skill" do
        bobby.skills << FactoryBot.create(:skill, category: :writing, user: bobby)
        get :search, params: { query: "bobby", filter: "writing" }
        expect(assigns(:results)).to include(bobby)
      end
      it "should not return a user when querying for their name and a skill they dont have" do
        bobby.skills << FactoryBot.create(:skill, category: :writing, user: bobby)
        get :search, params: { query: "bobby", filter: "music" }
        expect(assigns(:results)).to_not include(bobby)
      end
    end

    context "with no queries and a filter" do
      it "should return a user with a matching skill" do
        bobby.skills << FactoryBot.create(:skill, category: :writing, user: bobby)
        get :search, params: { filter: "writing" }
        expect(assigns(:results)).to include(bobby)
      end
      it "should not return a user with a skill they dont have" do
        bobby.skills << FactoryBot.create(:skill, category: :writing, user: bobby)
        get :search, params: { filter: "music" }
        expect(assigns(:results)).to_not include(bobby)
      end
    end
  end

  describe "GET /ajax/user/hide" do
    context "while not logged in" do
      it "should gracefully fail" do
        post :profile_hide
        expect(response.status).to eq(403)
      end
    end
    context "while logged in" do
      before do
        session[:user] = bobby.id
      end
      context "" do
        it "should toggle boolean of a hidden field" do
          post :profile_hide, params: { section: "skills" }
          expect(response.status).to eq(200)
          expect(User.find(bobby.id).hidden["skills"]).to eq("true")
        end
      end
    end
  end

  describe 'GET /user/:id/message' do
    context 'while not logged in' do
      it 'should redirect away' do
        get :direct_message, params: { id: bobby.username }
        expect(response).to redirect_to('/signup')
      end
    end
    context 'while logged in' do
      let(:admin_bobby) { FactoryBot.create(:administrator_user) }
      before do
        session[:user] = bobby.id
      end
      it 'should fail gracefully when a user tries to send a message to themselves' do
        get :direct_message, params: { id: bobby.username }
        expect(response).to redirect_to(root_url)
        expect(flash[:info]).to be_present
      end
      it 'should redirect to an existing session if a user tries to contact a user they already have a session with' do
        chat = Chat.create(users: [admin_bobby, bobby])
        get :direct_message, params: { id: admin_bobby.username }
        expect(response).to redirect_to("/messages/#{chat.id}")
      end
      it 'should not fail when trying to create a new chat session' do
        get :direct_message, params: { id: admin_bobby.username }
        expect(assigns(:users)).to be_present
        expect(assigns(:message)).to be_present
      end
    end
  end
end
