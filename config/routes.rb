Rails.application.routes.draw do
  root 'pages#main'
  get '/build', to: 'pages#build'
end

