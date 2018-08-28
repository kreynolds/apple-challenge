Rails.application.routes.draw do
  get '/top_urls', to: 'reports#top_urls', format: :json
  get '/top_referers', to: 'reports#top_referers', format: :json
  get '/top_referrers', to: 'reports#top_referers', format: :json # To match the challenge, not RFC1945 (should maybe 301?)
end
