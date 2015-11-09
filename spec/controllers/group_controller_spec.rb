require 'rails_helper'

RSpec.describe GroupController, type: :controller do
  let(:bobby) { FactoryGirl.create(:user) }
  let(:admin_bobby) { FactoryGirl.create(:administrator_user)}
  let(:group) { FactoryGirl.create(:group) }
  let(:membership) { FactoryGirl.create(:group_membership, user: bobby, group: group) }
  let(:admin_membership) { FactoryGirl.create(:group_membership, user: admin_bobby, group: group)}

  describe 'Test the unban system' do
    context 'when banned' do
      before do
        session[:user] = bobby.id
      end
      it 'should unban the user when their ban period is up' do
        membership.ban("dick", 2.weeks.from_now)
        expect(GroupMembership.find(membership.id).role).to eq("banned")
        get :show, id: group.slug
        expect(GroupMembership.find(membership.id).role).to eq("banned")
        membership.ban("dick", 2.weeks.ago)
        get :show, id: group.slug
        expect(GroupMembership.find(membership.id).role).to_not eq("banned")
      end
    end
  end

  describe "GET /group" do
    context 'when not logged in' do
      it 'should return all groups and no user group variable' do
        get :index
        expect(response).to render_template("index")
        expect(assigns(:groups)).to_not be_nil
        expect(assigns(:user_groups)).to be_nil
      end
    end
    context 'when logged in' do
      before do
        session[:user] = bobby.id
      end
      it 'should return all groups and user groups' do
        get :index
        expect(response).to render_template("index")
        expect(assigns(:groups)).to_not be_nil
        expect(assigns(:user_groups)).to_not be_nil
      end
    end
  end

  describe "POST /group" do
    context 'when not logged in' do
      it 'should return groups when requesting source all' do
        get :index_ajax, {source: "all", page: 0}
        expect(assigns(:groups)).to include(group)
      end
      it 'should fail gracefully when missing a page parameter' do
        get :index_ajax, {source: "all"}
        expect(response.status).to eq(403)
        expect(assigns(:groups)).to be_nil
      end
      it 'should fail gracefully when requesting source user' do
        get :index_ajax, {source: "user", page: 0}
        expect(response.status).to eq(403)
        expect(assigns(:groups)).to be_nil
      end
    end
    context 'when logged in' do
      before do
        session[:user] = bobby.id
      end
      it 'should fail gracefully when passed an invalid source parameter' do
        get :index_ajax, {source: "invalid", page: 0}
        expect(response.status).to eq(403)
        expect(assigns(:groups)).to be_nil
      end
      it 'should return groups when requesting source all' do
        get :index_ajax, {source: "all", page: 0}
        expect(assigns(:groups)).to include(group)
      end
      it 'should return groups the user is a member of when requesting source user' do
        membership.valid? # It fails if this isn't called. What in the fuck, factory girl?
        get :index_ajax, {source: "user", page: 0}
        expect(assigns(:groups)).to include(group)
      end
    end
  end

  describe "GET /group/new" do
    context 'when not logged in' do
      it 'should gracefully fail' do
        get :new
        expect(response).to_not render_template(:new)
        expect(response).to redirect_to('/signup')
      end
    end
    context 'when logged in' do
      before do
        session[:user] = bobby.id
      end
      context 'and banned' do
        it 'should gracefully fail' do
          bobby.ban("dick", 2.weeks.from_now)
          get :new
          expect(response).to_not render_template(:new)
          expect(response).to redirect_to(root_url)
          expect(flash[:warning]).to be_present
        end
      end
      it 'should render the new template' do
        get :new
        expect(response).to render_template(:new)
      end
    end
  end

  describe "POST /group/new" do
    context 'when not logged in' do
      it 'should gracefully fail' do
        post :create, group: {title: "newgroup", description: "", membership: "public_membership", privacy: "public_group" }
        expect(assigns(:group)).to_not be_present
        expect(response).to_not redirect_to('/group/newgroup')
        expect(response).to redirect_to('/signup')
      end
    end
    context 'when logged in' do
      before do
        session[:user] = bobby.id
      end
      context 'and banned' do
        it 'should gracefully fail' do
          bobby.ban("dick", 2.weeks.from_now)
          post :create, group: {title: "newgroup", description: "", membership: "public_membership", privacy: "public_group" }
          expect(assigns(:group)).to_not be_present
          expect(response).to_not redirect_to('/group/newgroup')
          expect(flash[:warning]).to be_present
        end
      end
      it 'should create the group and assign the user as owner' do
        post :create, group: {title: "newgroup", description: "", membership: "public_membership", privacy: "public_group" }
        expect(response).to redirect_to('/group/newgroup')
        expect(Group.last.title).to eq("newgroup")
        expect(Group.last.group_memberships.first.user).to eq(bobby)
        expect(Group.last.group_memberships.first.role).to eq("owner")
      end
      it 'should fail when parameters are missing' do
        post :create, group: {description: ""}
        expect(response).to_not redirect_to('/group/newgroup')
        expect(assigns(:group).valid?).to eq(false)
      end
    end
  end

  describe "POST /group/:id/delete" do
    context 'when not logged in' do
      it 'should fail gracefully' do
        post :delete, id: group.slug, confirmation: group.title
        expect(response).to redirect_to('/signup')
      end
    end
    context 'when logged in' do
      before do
        session[:user] = bobby.id
      end
      context 'but not the owner of the group' do
        it 'should fail gracefully' do
          post :delete, id: group.slug, confirmation: group.title
          expect(response).to redirect_to(root_url)
          expect(flash[:warning]).to be_present
          expect(Group.find(group.id)).to_not be_blank
        end
      end
      context 'and is the owner of the group' do
        before do
          membership.role = :owner
          membership.save
        end
        context 'and the group has other users in it' do
          before do
            # Ensure they're recognised.
            membership.valid?
            admin_membership.valid?
          end
          it 'should fail gracefully' do
            post :delete, id: group.slug, confirmation: group.title
            expect(response).to redirect_to(root_url)
            expect(flash[:warning]).to be_present
            expect(Group.find(group.id)).to_not be_blank
          end
        end
        context 'and the group has no other users in it' do
          before do
            admin_membership.destroy
          end
          context 'and the confirmation does not match the title' do
            it 'should fail gracefully' do
              post :delete, id: group.slug, confirmation: group.title + "blah"
              expect(response).to redirect_to(root_url)
              expect(flash[:warning]).to be_present
              expect(Group.find(group.id)).to_not be_blank
            end
          end
          it 'should delete the group' do
            post :delete, id: group.slug, confirmation: group.title
            expect(Group.where(slug: group.slug)).to be_blank
            expect(response).to_not redirect_to(root_url)
            expect(response).to redirect_to("/group")
            expect(flash[:warning]).to_not be_present
          end
        end
      end
    end
  end

  describe "GET /group/:id" do
    it 'should set the group and show the group template' do
      get :show, id: group.slug
      expect(response).to render_template(:show)
      expect(assigns(:group)).to eq(group)
      expect(response.status).to eq(200)
    end
    context 'when passed an invalid group' do
      it 'should create a 404 error' do
        get :show, id: "doesnt_exist"
        expect(response.status).to eq(404)
      end
    end
  end

  describe "PATCH /group/:id" do
    context 'when not logged in' do
      it 'should fail gracefully' do
        patch :update, id: group.slug, group: { description: "Dicks" }
        expect(response).to redirect_to('/signup')
      end
    end
    context 'when logged in' do
      before do
        session[:user] = bobby.id
      end
      context 'and banned' do
        it 'should fail gracefully' do
          membership.ban("dick", 2.weeks.from_now)
          post :update, id: group.slug, group: { description: "dicks", membership: "owner_verified", privacy: "management_only_post" }
          expect(response).to_not redirect_to("/group/#{group.slug}")
          expect(flash[:warning]).to be_present
          expect(Group.find(group.id).description).to_not eq("dicks")
        end
      end
      context 'and the user is the owner' do
        before do
          membership.role = "owner"
          membership.save
        end

        it 'should update the group when passed new parameters' do
          old_desc = group.description
          post :update, id: group.slug, group: { description: "dicks"}
          expect(response).to redirect_to("/group/#{group.slug}")
          expect(Group.find(group.id).description).to_not eq(old_desc)
          expect(Group.find(group.id).description).to eq("dicks")
        end

        it 'should fail gracefully when invalid parameters are passed' do
          new_desc = SecureRandom.hex(2000)
          post :update, id: group.slug, group: { description: new_desc}
          expect(response).to render_template("show")
          expect(Group.find(group.id).description).to_not eq(new_desc)
        end
      end
      it 'should fail gracefully as the user lacks the permission' do
        old_desc = group.description
        post :update, id: group.slug, group: { description: "dicks"}
        expect(response).to redirect_to(root_url)
        expect(response).to_not redirect_to("/group/#{group.slug}")
        expect(flash[:warning]).to be_present
        expect(Group.find(group.id).description).to eq(old_desc)
        expect(Group.find(group.id).description).to_not eq("dicks")
      end
    end
    context 'and the user is a global admin' do
      before do
        session[:user] = admin_bobby.id
      end
      it 'should let the user change otherwise unchangable parameters' do
        newtitle = SecureRandom.hex(5)
        post :update, id: group.slug, group: { title: newtitle, official: true}
        slug = newtitle.parameterize('_')
        expect(response).to redirect_to("/group/#{slug}")
        expect(Group.find(group.id).title).to eq(newtitle)
        expect(Group.find(group.id).official).to eq(true)
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

  describe "GET /group/:id/join" do
    context 'when not logged in' do
      it 'should fail gracefully' do
        get :join, id: group.slug
        expect(response).to redirect_to('/signup')
      end
    end
    context 'when logged in' do
      before do
        session[:user] = bobby.id
        membership.delete
      end
      context 'and globally banned' do
        it 'should reject the user from joining' do
          bobby.ban("dick", 2.weeks.from_now)
          get :join, id: group.slug
          expect(group.group_memberships.map(&:user)).to_not include(bobby)
        end
      end
      context 'and the group is invite only' do
        before do
          group.membership = :invite_only
          group.save
        end
        it 'should reject the user from joining' do
          get :join, id: group.slug
          expect(group.group_memberships.map(&:user)).to_not include(bobby)
        end
      end
      context 'and the user is already part of the group' do
        before do
          session[:user] = admin_bobby.id
        end
        it 'should reject the user from joining' do
          get :join, id: group.slug
          expect(group.group_memberships.map(&:user)).to_not include(bobby)
        end
      end
      context 'and the group is owner verified' do
        before do
          group.membership = :owner_verified
          group.save
        end
        it 'should join the group but be marked as an unverified user' do
          get :join, id: group.slug
          expect(group.group_memberships.map(&:user)).to include(bobby)
          expect(group.group_memberships.last.role).to eq("unverified")
        end
      end
      context 'when the membership conditions are invalid' do
        it 'should generate an error' do
          get :join, id: group.slug, invalid: true
          expect(group.group_memberships.map(&:user)).to_not include(bobby)
          expect(flash[:info]).to include("error")
        end
      end
      it 'should join the group' do
        get :join, id: group.slug
        expect(group.group_memberships.map(&:user)).to include(bobby)
        expect(group.group_memberships.last.role).to eq("member")
      end
    end
  end

  describe "GET /group/:id/leave" do
    context 'when not logged in' do
      it 'should fail gracefully' do
        get :leave, id: group.slug
        expect(response).to redirect_to('/signup')
      end
    end
    context 'when logged in' do
      before do
        session[:user] = bobby.id
      end
      context 'when not member of group' do
        before do
          membership.delete
        end
        it 'should gracefully fail' do
          get :leave, id: group.slug
          expect(response).to redirect_to(root_url)
          expect(flash[:warning]).to be_present
        end
      end
      context 'when banned from group' do
        it 'should fail gracefully' do
          membership.ban("dick", 2.weeks.from_now)
          get :leave, id: group.slug
          expect(response).to redirect_to(root_url)
          expect(flash[:warning]).to be_present
          expect(GroupMembership.find(membership.id)).to be_present
        end
      end
      context 'when owner of the group' do
        before do
          membership.role = :owner
          membership.save
        end
        it 'should fail gracefully' do
          get :leave, id: group.slug
          expect(response).to redirect_to(root_url)
          expect(flash[:warning]).to be_present
          expect(flash[:warning]).to include("owner")
          expect(GroupMembership.find(membership.id)).to be_present
        end        
      end
      it 'should destroy the membership of the user' do
        expect(GroupMembership.find(membership.id)).to be_present
        get :leave, id: group.slug
        expect(response).to redirect_to(root_url)
        expect { GroupMembership.find(membership.id) }.to raise_error(ActiveRecord::RecordNotFound)
      end
    end
  end

  describe "GET /group/search" do
    it 'should return groups when searched for' do
      get :search, query: group.title
      expect(response).to_not redirect_to('/signup')
      expect(assigns(:groups)).to_not be_nil
      expect(assigns(:groups).map(&:title)).to include(group.title)
      expect(response).to render_template('search')
    end

    it 'should return groups using the raw cards template when the raw parameter is passed' do
      get :search, query: group.title, raw: true
      expect(response).to_not redirect_to('/signup')
      expect(assigns(:groups)).to_not be_nil
      expect(assigns(:groups).map(&:title)).to include(group.title)
      expect(response).to render_template('raw_cards')
    end
  end
end
