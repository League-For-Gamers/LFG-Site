require 'rails_helper'

RSpec.describe GroupController, type: :controller do
  let(:bobby) { FactoryGirl.create(:user) }
  let(:group) { FactoryGirl.create(:group) }
  before do
    FactoryGirl.create(:group_membership, user: bobby, group: group)
  end

  describe "GET /group/:id" do
    it 'should set the group and show the group template' do
      get :show, id: group.slug
      expect(response).to render_template(:show)
      expect(assigns(:group)).to eq(group)
    end
    context 'when passed an invalid group' do
      it 'should create a 404 error' do
        get :show, id: "doesnt_exist"
        expect(response.status).to eq(404)
      end
    end
  end
  describe "POST /group/:id/new_post" do
    context 'when not logged in' do
      it 'should fail gracefully' do
        post :create_post, id: group.slug
        expect(response).to redirect_to('/signup')
      end
    end
    context 'when logged in' do
      before do
        session[:user] = bobby.id
      end
      it 'should create a new post when passed valid parameters' do
        body = "Test post body"
        post :create_post, {id: group.slug, body: body}
        expect(group.posts.last.body).to eq(body)
      end
      context "while being an administrator and passing the official flag" do
        let(:admin_bobby) { FactoryGirl.create(:administrator_user) }
        before do
          FactoryGirl.create(:group_membership, user: admin_bobby, group: group, role: :owner)
          session[:user] = admin_bobby.id
        end
        it 'should create an official group post' do
          body = "Test post body"
          post :create_post, {id: group.slug, body: body, official: true}
          post = group.posts.where(official: true).last
          expect(post.body).to eq(body)
          expect(post.official).to be(true)
        end
      end
    end
  end
end
