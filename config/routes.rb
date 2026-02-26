Rails.application.routes.draw do
  root "sessions#new"
  resource :session, only: [:new, :create]

  resources :assessments, only: [:create, :show] do
    member { patch :submit }
    resources :questions, only: [:show, :update],
              controller: "assessment_questions"
  end

  resources :results, only: [:show], param: :assessment_id
  resource :account, only: [:new, :create]
  resources :consents, only: [:new, :create, :show, :update]
  resources :deletion_requests, only: [:new, :create, :show]

  namespace :admin do
    root "dashboard#index"
    resource :dashboard, only: [] do
      get :completion_rates
      get :drop_off_analysis
    end
    resources :question_sets
    resources :alerts, only: [:index, :show, :update]
    resources :audit_logs, only: [:index, :show]
  end

  get "up" => "rails/health#show", as: :rails_health_check
end
