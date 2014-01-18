GeomodelCassandraDemo::Application.routes.draw do
  get 'schools/search', as: :school_search
  get "schools/index"
  root 'schools#index'
end
