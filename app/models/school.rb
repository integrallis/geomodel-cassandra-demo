class School < Hashie::Mash
  extend ActiveModel::Callbacks
  
  #include ActiveModel::SerializerSupport
  include ActiveModel::Dirty
  include ActiveModel::Validations
  include ActiveModel::Validations::Callbacks
  #include ActiveModel::Conversion
  include ActiveModel::Observing

  def full_address
    "#{address}, #{city}, #{state}, #{zipcode}#{zipcode4.blank? ? '' : '-' + zipcode4}"
  end

  def geocode_address
    
      geocoder_results = begin
        Geocoder.search(full_address)
      rescue => e
        puts "Exception Geocoding #{full_address}: #{e}"
        []
      end
    
    unless geocoder_results.empty?
      geo_location = geocoder_results.first
      
      self.latitude = geo_location.latitude
      self.longitude = geo_location.longitude
      
      point = Geomodel::Types::Point.new(self.latitude, self.longitude)
      self.geocells = Geomodel::GeoCell.generate_geocells(point)
      self.geocoded = true
    else
      self.geocoded = false
      #errors.add(:address, "Could not Geocode address") 
      puts "Could not geocode address"
    end
  end
  
  def location
    Geomodel::Types::Point.new(self.latitude, self.longitude)
  end
    
  #
  # Data persistence
  #              
  
  def self.all
    CassandraMigrations::Cassandra.select(:schools).map { |attributes| School.new(attributes) }
  end
  
  def self.find(id)
    School.new(CassandraMigrations::Cassandra.select(:schools,
      :selection => "id = #{id}",
      :limit => 1
    ).first)
  end
  
  def self.first
    School.new(CassandraMigrations::Cassandra.select(:schools,
      :limit => 1
    ).first)
  end
  
  def self.where(pks, options = {})
    selection = pks.reject { |n,v| v.nil? }.map { |n,v| "#{n} = '#{v}'" }.join(' AND ')
    
    CassandraMigrations::Cassandra.select(
      :schools,
      :selection => selection
    ).map { |attributes| School.new(attributes) }
  end
  
  def update_attributes(attributes, options = {})
    attributes.each do |k, v|
      if respond_to?("#{k}=")
        send("#{k}=", v)
      else
        raise(UnknownAttributeError, "unknown attribute: #{k}")
      end
    end
    update(attributes)
  end
  
  def destroy
  end
  
  def errors
    []
  end
  
  def save
    CassandraMigrations::Cassandra.write!(:schools, self.to_hash)
    true
  end
  
  def update(attributes = {})
    to_be_updated = attributes.empty? ? self.to_hash.delete_if { |k,v| k == 'id' } : attributes.delete_if { |k,v| v.nil? }
    CassandraMigrations::Cassandra.update!(:schools, "id = #{self.id}", to_be_updated)
    true
  end
  
  def self.create(attributes = {})
    object = self.new(attributes)
    uuid = SimpleUUID::UUID.new
    guid = Cql::Uuid.new(uuid.to_guid)
    object.id = guid
    object.geocode_address
    puts "CREATED OBJECT with id #{object.id} and geocells ==> #{object.geocells}"
    object.geocells.each do |geocell|
      CassandraMigrations::Cassandra.update!(:geocells, "geocell = '#{geocell}'",
                                             {schools: [object.id]},
                                             {operations: {schools: :+}})
    end unless object.geocells.nil?
    object.save
    object
  end
  
  def self.delete_all
    how_many = self.count
    CassandraMigrations::Cassandra.truncate!(:schools)
    how_many
  end
  
  def self.count
    CassandraMigrations::Cassandra.execute('SELECT COUNT(*) FROM schools;').first["count"]
  end
  
  #
  # Geocell queries
  #
  def self.find_schools_near(latitude, longitude, max_results, radius)
    query_runner = lambda do |geocells|
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
  
  SCHOOL_STATUS = {
    '1' => 'Operational',
    '2' => 'Closed',
    '3' => 'Opened',
    '4' => 'Operational but not on CCD list',
    '5' => 'Affiliated with different education agency',
    '6' => 'Temporarily Closed',
    '7' => 'Schedule to be operational within 2 years',
    '8' => 'Reopened'
  }
  
  SCHOOL_TYPE = {
    '1' => 'Regular school',
    '2' => 'Special education school',
    '3' => 'Vocational school',
    '4' => 'Other/alternative school',
    '5' => 'Reportable program'
  }
  
  SCHOOL_LEVEL = {
    '1' => 'Primary',
    '2' => 'Middle',
    '3' => 'High',
    '4' => 'Other'
  }
  
  SCHOOL_GRADE = {
    'UG' => 'Ungraded',
    'PK' => 'Prekindergarten',
    'KG' => 'Kindergarten',
    '01' => '1st',
    '02' => '2nd',
    '03' => '3rd',
    '04' => '4th', 
    '05' => '5th',
    '06' => '6th',
    '07' => '7th',
    '08' => '8th',
    '09' => '9th',
    '10' => '10th',
    '11' => '11th',
    '12' => '12th',       
    'N' => 'No students reported'
  }
end
