Rails.application.routes.draw do
  root 'pages#main'
  get 'build', to: 'pages#build'
  get 'image', to: 'pages#image'
  get 'position', to: 'robot#position'
  get 'running', to: 'robot#running'
  get 'trajectory', to: 'pages#trajectory'

  get 'settings', to: 'settings#index'
  post 'update_config', to: 'settings#update'

  post 'velocity', to: 'robot#velocity'
  post 'acceleration', to: 'robot#acceleration'
  post 'run', to: 'robot#run'
  post 'stop', to: 'robot#stop'
  post 'next', to: 'robot#next_trajectory'
  post 'prev', to: 'robot#prev_trajectory'
end

