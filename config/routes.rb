Rails.application.routes.draw do
  root 'pages#main'
  get 'build', to: 'pages#build'
  get 'image', to: 'pages#image'
  get 'state', to: 'robot#state'
  get 'trajectory', to: 'pages#trajectory'

  get 'settings', to: 'settings#index'
  post 'update_config', to: 'settings#update'

  get 'calibrate', to: 'calibration#index'
  post 'adjust', to: 'calibration#adjust'
  post 'manual', to: 'calibration#manual'
  post 'move', to: 'calibration#move'

  post 'velocity', to: 'robot#velocity'
  post 'acceleration', to: 'robot#acceleration'
  post 'run', to: 'robot#run'
  post 'stop', to: 'robot#stop'
  post 'next', to: 'robot#next_trajectory'
  post 'prev', to: 'robot#prev_trajectory'
end

