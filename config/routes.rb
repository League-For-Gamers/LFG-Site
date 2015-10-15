Rails.application.routes.draw do
  root 'feed#feed'

  get 'feed.:format', to: 'feed#feed'

  get  'login', to: 'user#login'
  post 'login', to: 'user#login_check'
  get  'signup', to: 'user#signup'
  post 'signup', to: 'user#create'
  get  'logout', to: 'user#logout'
  get 'account', to: 'user#my_account'
  patch 'account', to: 'user#update'
  
  get 'search', to: 'user#search'

  get 'timeline', to: 'feed#timeline'

  namespace :messages, path: 'messages' do
    root action: 'index'
    # put '/new', action: 'new'
    put '/', action: 'create_chat'
    get '/:id', action: 'show'
    put '/:id', action: 'create_message'
    get '/:id/older', action: 'older_messages'
    get '/:id/newer', action: 'new_messages'
  end

  namespace :feed, path: 'feed' do
    post 'new_post', action: 'create'
    get '/official', action: 'official_feed'
    get '/user/:user_id', action: 'user_feed'
    get '/user/:user_id/:post_id', action: 'show'
    patch '/user/:user_id/:id', action: 'update'
    delete '/user/:user_id/:id', action: 'delete'
  end

  namespace :group, path: 'group' do
    get  ':id', action: 'show'
    post ':id/new_post', action: 'create_post'
  end

  namespace :user, path: 'user' do
    get '/forgot_password', action: 'forgot_password'
    post '/forgot_password', action: 'forgot_password_check'
    get '/forgot_password/:activation_id', action: 'reset_password'
    post '/forgot_password/:activation_id', action: 'reset_password_check'
    get ':id', action: 'show'
    get ':id/message', action: 'direct_message'
    get ':id/follow', action: 'follow'
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
