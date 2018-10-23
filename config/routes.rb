Rails.application.routes.draw do
  root 'pages#main'
  get 'build', to: 'pages#build'
  get 'image', to: 'pages#image'
  get 'position', to: 'robot#position'
  post 'velocity', to: 'robot#velocity'
  post 'acceleration', to: 'robot#acceleration'
end

