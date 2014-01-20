Geocoder.configure(

  # geocoding service (see below for supported options):
  :lookup => ENV['GEOCODER_PROVIDER'].nil? ? :bing : ENV['GEOCODER_PROVIDER'].to_sym,

  # to use an API key:
  :api_key => ENV['GEOCODER_API_KEY'], 

  # geocoding service request timeout, in seconds (default 3):
  :timeout => 5,
  
  :mapquest => {:licensed => true}
)