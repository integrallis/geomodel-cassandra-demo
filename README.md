# Geomodel Cassandra Demo

A Rails 4 Demo of the GeoModel Ruby (https://github.com/integrallis/geomodel) Library using Cassandra (http://cassandra.apache.org/)

Following the lead of the Python implementation of GeoModel (https://code.google.com/p/geomodel/). 
We are seeding a Cassandra Database with data from the National Center of Education Statistics (http://nces.ed.gov/) with
data from all registered schools in the US. 

Three CSV files are loaded by the seeds can be found under the db/seeds/sc091_a_csv directory. The file db/seeds/school_seeds.rb
parses the CSV files, geocodes the School addresses using the GeoCoder Gem (http://rubygeocoder.com/) and uses the GeoModel Gem to calculate the geocells for each address.

## Cassandra

The school information and their geocell list are stored in the school table (maintained with CassandraMigrations https://github.com/hsgubert/cassandra_migrations ):

```ruby
create_table :schools, :primary_keys => :id do |t|
  t.uuid :id
  t.string :school_id
  t.string :name
  t.string :address
  t.string :city
  t.string :state
  t.string :zipcode
  t.string :zipcode4
  t.string :number_of_students
  t.string :phone
  t.string :urbanicity_code
  t.string :school_type
  t.string :school_level
  t.string :low_grade_offered
  t.string :high_grade_offered
  t.string :school_status
  t.double :latitude
  t.double :longitude
  t.set :geocells, :type => :string
  t.boolean :geocoded
end
```

A reverse lookup table that stores a mapping of geocells to school_ids is also maintained:

```ruby
create_table :geocells, :primary_keys => :geocell do |t|
  t.string :geocell
  t.set :schools, :type => :uuid
end
```

## GeoModel

The School model (a Hashie ActiveRecord-like Ruby implementation) has a class method do find schools near a given latitude and longitude.
The method creates a lambda (query_runner) to be passed the Geomodel#proximity_fetch method. The proximity_fetch methods invokes the query_runner passing a list of matching geocells.

The query looks up all schools for the matching geocells in the geocells reverse lookup table:

```ruby
#
# Geocell queries
#
def self.find_schools_near(latitude, longitude, max_results, radius)
  query_runner = lambda do |geocells|
    # more complex select query 
    school_ids = CassandraMigrations::Cassandra.select(
      :geocells, 
      :projection => 'schools',
      :selection => "geocell IN ('#{geocells.join("', '")}')"
    ).to_a.map { |r| r["schools"].map(&:to_s) }.flatten.uniq
    
    unless school_ids.empty?
      CassandraMigrations::Cassandra.select(
        :schools,
        :selection => "id IN (#{school_ids.to_a.map(&:to_s).join(",")})"
      ).map { |attributes| School.new(attributes) }
    else
      []
    end
  end
  
  Geomodel.proximity_fetch(Geomodel::Types::Point.new(latitude, longitude), query_runner, max_results, radius)
end
```

## UI

The UI is a simple Google Map rendered using Gmaps4Rails (https://github.com/apneadiving/Google-Maps-for-Rails). You can
search by address or you can move the map to certain position and double click to perform a nearest search (fixed at 15 miles radius)
of the clicked location

## Configuration

Add a .env (https://github.com/bkeepers/dotenv) at the root of your application. In this file you'll need to

* CASSANDRA_URL: Optional, if you C* db (cluster) is not collocated with your Rails app
* GEOCODER_API_KEY: A geocoding service provider API key to be used by GeoCoder






