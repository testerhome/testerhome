Rails.application.routes.draw do

  mount RuCaptcha::Engine => "/rucaptcha"
  use_doorkeeper do
    controllers applications: 'oauth/applications', authorized_applications: 'oauth/authorized_applications'
  end

  require 'sidekiq/web'

  resources :sites
  resources :pages, path: "wiki" do
    collection do
      get :recent
      post :preview
    end
    member do
      get :comments
    end
  end
  resources :comments
  resources :notes do
    collection do
      post :preview
    end
  end

  root to: "home#index"

  devise_for :users, path: "account", controllers: {
      registrations: :account,
      sessions: :sessions,
      omniauth_callbacks: "users/omniauth_callbacks"
    }

  delete "account/auth/:provider/unbind" => "users#auth_unbind", as: 'unbind_account'
  post "account/update_private_token" => "users#update_private_token", as: 'update_private_token_account'

  resources :notifications, only: [:index, :destroy] do
    collection do
      post :clear
      get :unread
    end
  end

  resources :nodes do
    member do
      post :block
      post :unblock
    end
  end

  # for qa

  get "questions/node:id" => "questions#node", as: 'node_questions'
  get "questions/node:id/feed" => "questions#node_feed", as: 'feed_node_questions', defaults: { format: 'xml' }
  get "questions/last" => "questions#recent", as: 'recent_questions'


  resources :questions do
    member do
      post :answer
      post :favorite
      delete :unfavorite
      post :follow
      delete :unfollow
      post :close
      post :open
      post :action
    end
    collection do
      get :no_answer
      get :popular
      get :excellent
      get :feed, defaults: { format: 'xml' }
      get :feedgood, defaults: { format: 'xml' }
      post :preview
    end
    resources :answers
  end

  get "topics/node:id" => "topics#node", as: 'node_topics'
  get "topics/node:id/feed" => "topics#node_feed", as: 'feed_node_topics', defaults: { format: 'xml' }
  get "topics/last" => "topics#recent", as: 'recent_topics'

  resources :topics do
    member do
      post :reply
      post :favorite
      delete :unfavorite
      post :follow
      delete :unfollow
      post :close
      post :open
      post :action
    end
    collection do
      get :no_reply
      get :popular
      get :excellent
      get :feed, defaults: { format: 'xml' }
      get :feedgood, defaults: { format: 'xml' }
      post :preview
    end
    resources :replies
  end

  resources :ads
  resources :photos
  resources :likes
  resources :votes
  resources :jobs
  resources :bugs
  resources :opencourses


  get "/search" => "search#index", as: 'search'
  get '/search/users' => 'search#users', as: 'search_users'

  namespace :admin do
    root to: "home#index"
    resources :site_configs
    resources :replies
    resources :topics do
      member do
        post :suggest
        post :unsuggest
        post :undestroy
      end
    end
    resources :answers
    resources :questions do
      member do
        post :suggest
        post :unsuggest
        post :undestroy
      end
    end
    resources :nodes
    resources :sections
    resources :users
    resources :photos
    resources :pages do
      resources :versions, controller: :page_versions do
        member do
          post :revert
        end
      end
    end
    resources :comments
    resources :site_nodes
    resources :sites do
      member do
        post :undestroy
      end
    end
    resources :locations
    resources :exception_logs do
      collection do
        post :clean
      end
    end
    resources :applications
  end

  get "api" => "home#api", as: "api"
  get "timeline" => "home#timeline", as: "timeline"
  get "twitter" => "home#twitter", as: "twitter"
  get "markdown" => "home#markdown", as: "markdown"

  require "dispatch"
  mount Api::Dispatch => "/api"

  authenticate :user, lambda { |u| u.admin? } do
    mount Sidekiq::Web => '/sidekiq'
  end

  mount JasmineRails::Engine => "/specs" if defined?(JasmineRails)

  # WARRING! 请保持 User 的 routes 在所有路由的最后，以便于可以让用户名在根目录下面使用，而又不影响到其他的 routes
  # 比如 http://ruby-china.org/huacnlee
  get "users/city/:id" => "users#city", as: 'location_users'
  get "users" => "users#index", as: 'users'

  resources :users, path: "" do
    member do
      get :topics
      get :replies
      get :questions
      get :answers
      get :favorites
      get :notes
      get :blocked
      post :block
      post :unblock
      post :follow
      post :unfollow
      get :followers
      get :following
      get :calendar
    end
  end

  resources :polls, only: [:create, :update] do
    member do
      get :voters
    end
  end

  match '*path', via: :all, to: 'home#error_404'
end
