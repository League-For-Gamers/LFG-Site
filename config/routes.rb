Rails.application.routes.draw do
  root 'user#main'

  get  'login', to: 'user#login'
  post 'login', to: 'user#login_check'
  post 'signup', to: 'user#create'
  get  'logout', to: 'user#logout'
  get 'account', to: 'user#my_account'
  patch 'account', to: 'user#update'

  get 'search', to: 'user#search'

  namespace :user, path: 'user' do
    get ':id', action: 'show'
  end
end
