Rails.application.routes.draw do
  root to: 'web#login'
  get '/login' => 'web#login', as: 'login'
  get '/friends' => 'web#friends', as: 'friends'
end
