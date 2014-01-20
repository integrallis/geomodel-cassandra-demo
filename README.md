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

Install link:http://git-scm.com/[Git],  link:https://rvm.io/[RVM], link:http://www.postgresql.org/[PostgreSQL] and link:http://cassandra.apache.org/[Cassandra]


```shell
$ rvm get head
$ git clone https://github.com/BaseboxSoftware/specx.git
$ cd specx/ # prompted by RVM
$ bundle
$ rake db:migrate db:test:prepare
$ rake cassandra:setup cassandra:migrate cassandra:test:prepare
$ foreman start
```

Add a .env (https://github.com/bkeepers/dotenv) at the root of your application. In this file you'll need to

* CASSANDRA_URL: Optional, if you C* db (cluster) is not collocated with your Rails app
* GEOCODER_PROVIDER: The geocoder service provider see https://github.com/alexreisner/geocoder#geocoding-service-lookup-configuration
* GEOCODER_API_KEY: A geocoding service provider API key to be used by GeoCoder

### Cassandra Migrations and Heroku

The config/cassandra.yml file includes an ERB snippet to include the production Cassandra cluster URL. 

```ruby
production:
  host: <%= ENV['CASSANDRA_URL'] || '127.0.0.1' %>
  port: 9042
  keyspace: 'schools'
  replication:
    class: 'SimpleStrategy'
    replication_factor: 1
```

Since environment apps are no available during Heroku's Slug Compilation process we need to add the *user-env-compile* Heroku Labs
feature (https://devcenter.heroku.com/articles/labs-user-env-compile) that enable an app’s config vars present during the build. 
To do so use the heroku command on your application as shown next (replace geomodel with the name of your application):

```shell
+ heroku labs:enable user-env-compile -a geomodel

Enabling user-env-compile for geomodel... done
WARNING: This feature is experimental and may change or be removed without notice.
For more information see: http://devcenter.heroku.com/articles/labs-user-env-compile
```

Then, add the required variables to your Heroku application using:

```shell
heroku config:set CASSANDRA_URL=127.0.0.1
```

### Seeding the Database

The rake db:seed command can take two optional parameters, the list of states to process from the seed files (as a comma delimited list) and
the seed_file to be processed (first, second or last). I've done this so that you can stage the loading of seed data into multiple stages.

The seeds files have the suffixes 'ai', 'kn' and 'ow' for the letters of the states they encompass.

```shell
rake db:seed seed_states=wy seed_file=last
```







