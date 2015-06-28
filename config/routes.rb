Rails.application.routes.draw do
  root 'static#main'

  get  'login', to: 'users#login'
  post 'login', to: 'users#login_check'
  get  'signup', to: 'users#signup'
  post 'signup', to: 'users#create'
  get  'logout', to: 'users#logout'

  namespace :users, path: 'user' do
    get 'account', action: 'my_account'
    patch 'account', action: 'update'
    get ':id', action: 'show'
  end
end
