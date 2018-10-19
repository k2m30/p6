Rails.application.routes.draw do
  root 'pages#main'
  get '/build', to: 'pages#build'
  get 'image', to: 'pages#image'
end

