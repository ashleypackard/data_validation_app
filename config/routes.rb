Rails.application.routes.draw do
  namespace :api, :defaults => {:format => :json} do
    namespace :v1 do
      get "validate", to: 'validations#index'
    end
  end
end
