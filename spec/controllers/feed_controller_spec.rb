require 'rails_helper'

RSpec.describe FeedController, type: :controller do
  let(:bobby) { FactoryGirl.create(:user) }
  describe "GET /" do
    context "when not logged in" do
      it "redirects to signup page" do
        get :feed
        expect(response).to redirect_to('/signup')
        get :feed, format: :rss
        expect(response.status).to eq(403)
      end
    end
    context "when logged in" do
      before do
        session[:user] = bobby.id
      end
      it "shows the feed template" do
        get :feed
        expect(response).to render_template(:feed)
      end
      it "populates the @posts variable" do
        5.times { FactoryGirl.create(:post, user: bobby)}
        FactoryGirl.create(:post, user: bobby, official: true)
        get :feed
        expect(assigns(:posts)).to include(bobby.posts.last)
      end
      it "should respond to rss correctly" do
        get :feed, format: :rss
        expect(response).to render_template("feed/rss.html.erb")
      end
    end
  end

  describe "GET /timeline" do
    context 'on the main feed' do
      it 'should create 403 errors when all required variables are missing' do
        30.times { FactoryGirl.create(:post, user: bobby)}
        FactoryGirl.create(:post, user: bobby, official: true)
        get :timeline
        expect(response.status).to eq(403)
        get :timeline, feed: 'main'
        expect(response.status).to eq(403)
        get :timeline, feed: 'main', id: Post.all.order("created_at DESC")[1]
        expect(response.status).to eq(403)
        get :timeline, feed: 'main', id: Post.all.order("created_at DESC")[1], direction: 'newer'
        expect(response.status).to eq(403)
        get :timeline, feed: 'invalid', id: Post.all.order("created_at DESC")[1], direction: 'older'
        expect(response.status).to eq(403)
        get :timeline, feed: 'invalid', id: Post.all.order("created_at DESC")[1], direction: 'newer'
        expect(response.status).to eq(403)
        get :timeline, feed: 'main', id: Post.all.order("created_at DESC")[1], direction: 'invalid'
        expect(response.status).to eq(403)
        session[:user] = bobby.id
        get :timeline, feed: 'main', id: Post.all.order("created_at DESC")[1], direction: 'newer'
        expect(response.status).to_not eq(403)
      end
      context 'when polling for new posts' do
        before { session[:user] = bobby.id }
        it 'should respond with posts newer than the last' do
          30.times { FactoryGirl.create(:post, user: bobby)}
          FactoryGirl.create(:post, user: bobby, official: true)
          get :timeline, feed: 'main', id: Post.all.order("created_at DESC")[1], direction: 'newer'
          expect(response.status).to_not eq(403)
          expect(assigns(:posts)).to include(Post.all.order("created_at DESC").first)
        end
      end
      context 'when retrieving older posts' do
        before { session[:user] = bobby.id }
        it 'should respond with posts older than the last' do
          30.times { FactoryGirl.create(:post, user: bobby)}
          FactoryGirl.create(:post, user: bobby, official: true)
          get :timeline, feed: 'main', id: Post.all.order("created_at DESC")[1], direction: 'older'
          expect(response.status).to_not eq(403)
          expect(assigns(:posts)).to include(Post.all.order("created_at DESC").last)
        end
      end
    end
  end

  describe "GET /feed/official" do
    before do
      session[:user] = bobby.id
    end
    it "populates the @posts variable with official posts" do
      5.times { FactoryGirl.create(:post, user: bobby)}
      3.times { FactoryGirl.create(:post, user: bobby, official: true) }
      get :official_feed
      expect(assigns(:posts).length).to eq(3)
      expect(assigns(:posts).map(&:official)).to match_array([true, true, true])
    end
    it "should respond to rss correctly" do
      get :official_feed, format: :rss
      expect(response).to render_template("feed/rss.html.erb")
    end
  end

  describe "GET /feed/user/:user_id" do
    before do
      500.times { FactoryGirl.create(:post, user: bobby) }
    end
    it "only shows posts owned by the user" do
      get :user_feed, user_id: bobby.username
      expect(assigns(:posts).map(&:user).map(&:id)).to include(bobby.id)
    end
    it "404s when username is invalid" do
      get :user_feed, user_id: "non_existant"
      expect(response.status).to eq(404)
    end
    it "should respond to rss correctly" do
      get :user_feed, user_id: bobby.username, format: :rss
      expect(response).to render_template("feed/rss.html.erb")
    end
  end
  describe "GET /feed/user/:user_id/:post_id" do
    let(:post) { FactoryGirl.create(:post, user: bobby) }
    it "sets @post" do
      get :show, user_id: bobby.username, post_id: post.id
      expect(assigns(:post)).to eq(post)
    end
    it "renders an error for an invalid id" do
      get :show, user_id: bobby.username, post_id: 9953259
      expect(response).to render_template('shared/not_found')
      expect(response.status).to eq(404)
    end
  end

  describe "DELETE /feed/user/:user_id/:post_id" do
    let(:new_post) { FactoryGirl.create(:post, user: bobby) }
    context "when user is not logged in" do
      it "should fail gracefully" do
        delete :delete, user_id: bobby.id, id: new_post.id
        expect(response.status).to eq(403)
      end
    end

    context "when user does not own the post" do
      let(:new_user) { FactoryGirl.create(:user, username: "new_user", display_name: nil, email: "new@email.com", email_confirm: "new@email.com") }
      before do
        session[:user] = new_user.id
      end
      it "should fail gracefully" do
        delete :delete, user_id: bobby.id, id: new_post.id
        expect(response.status).to eq(403)
      end
    end

    context "when the user owns the post" do
      before do
        session[:user] = bobby.id
      end
      it "should delete the post" do
        delete :delete, user_id: bobby.id, id: new_post.id
        expect(Post.all).to_not include(new_post)
      end
    end
  end

  describe "PATCH /feed/user/:user_id/:post_id" do # I should really change this route to PATCH /user/:user_id/:post_id
    let(:new_post) { FactoryGirl.create(:post, user: bobby) }
    context "when user is not logged in" do
      it "should fail gracefully" do
        patch :update, user_id: bobby.id, id: new_post.id, body: "new body goes here"
        expect(response.status).to eq(403)
      end
    end

    context "when user does not own the post" do
      let(:new_user) { FactoryGirl.create(:user, username: "new_user", display_name: nil, email: "new@email.com", email_confirm: "new@email.com") }
      before do
        session[:user] = new_user.id
      end
      it "should fail gracefully" do
        patch :update, user_id: bobby.id, id: new_post.id, body: "new body goes here"
        expect(response.status).to eq(403)
      end
    end

    context "when the user owns the post" do
      before do
        session[:user] = bobby.id
      end
      it "should edit the post" do
        patch :update, user_id: bobby.id, id: new_post.id, body: "new body goes here"
        expect(Post.find(new_post.id).body).to_not eq(new_post.body)
      end
      context "when the post is invalid" do
        it "should fail gracefully" do
          body = ""
          300.times { body << "test test "}
          patch :update, user_id: bobby.id, id: new_post.id, body: body
          expect(response.status).to eq(422)
        end
      end
    end
  end

  describe "POST /feed/new_post" do
    context "while not logged in" do
      it "should redirect to /signup" do
        post :create
        expect(response).to redirect_to('/signup')
      end
    end
    context "while logged in" do
      before do
        session[:user] = bobby.id
      end
      context "while passing arguments" do
        it "creates a new post" do
          body = "Test post body"
          post :create, {body: body}
          expect(response).to redirect_to(root_url)
          expect(bobby.posts.last.body).to eq(body)
        end
        context "while being an administrator and passing the official flag" do
          let(:admin_bobby) { FactoryGirl.create(:administrator_user) }
          before do
            session[:user] = admin_bobby.id
          end
          it "create a new official post" do
            body = "Test post body"
            post :create, {body: body, official: true}
            expect(response).to redirect_to(root_url)
            expect(admin_bobby.posts.last.body).to eq(body)
            expect(admin_bobby.posts.last.official).to be(true)
          end
        end
      end
    end
  end
end
