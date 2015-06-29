Rails.application.routes.draw do
  root 'static#main'

  get  'login', to: 'user#login'
  post 'login', to: 'user#login_check'
  get  'signup', to: 'user#signup'
  post 'signup', to: 'user#create'
  get  'logout', to: 'user#logout'

  namespace :user, path: 'user' do
    get 'account', action: 'my_account'
    patch 'account', action: 'update'
    get ':id', action: 'show'
  end
end
