Rails.application.routes.draw do
  root 'user#main'

  get  'login', to: 'user#login'
  post 'login', to: 'user#login_check'
  get  'signup', to: 'user#signup'
  post 'signup', to: 'user#create'
  get  'logout', to: 'user#logout'
  get 'account', to: 'user#my_account'
  patch 'account', to: 'user#update'
  post 'new_post', to: 'user#create_post'

  get 'search', to: 'user#search'

  namespace :user, path: 'user' do
    post '/post/update', action: 'update_post'
    post '/post/delete', action: 'delete_post'
    get ':id', action: 'show'
    get ':user_id/:post_id', action: 'show_post'
  end

  scope :ajax do
    namespace :user, path: 'user' do
      post 'hide', action: 'profile_hide'
    end
  end

  get 'terms', to: 'static#terms'
  get 'faq', to: 'static#faq'
  get 'privacy', to: 'static#privacy'
end
