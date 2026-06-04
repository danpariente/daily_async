Rails.application.routes.draw do
  root "pages#recorder"            # grabador (página pública para los devs)
  resources :clips,   only: %i[create]
  resources :dailies, only: %i[index]   # tablero del lead
end
