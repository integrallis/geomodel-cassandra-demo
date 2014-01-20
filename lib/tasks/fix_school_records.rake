namespace :db do
  desc "Find School records that could not be Geocoded and generates their geocells"
  task :fix_school_records => :environment do
    schools = CassandraMigrations::Cassandra.select(
      :schools,
      :selection => "geocoded=false"
    ).map { |attributes| School.new(attributes) }
    
    schools.each do |school|
      school.geocode_address
      if school.geocoded 
        school.save
        school.geocells.each do |geocell|
          CassandraMigrations::Cassandra.update!(:geocells, "geocell = '#{geocell}'",
                                                 {schools: [school.id]},
                                                 {operations: {schools: :+}})
        end unless school.geocells.nil?
      end
    end
  end
end