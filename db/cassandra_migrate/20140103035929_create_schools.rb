class CreateSchools < CassandraMigrations::Migration
  def up
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
    
    create_index :schools, :city, :name => 'by_city'
    create_index :schools, :state, :name => 'by_state'
    create_index :schools, :zipcode, :name => 'by_zipcode'
    create_index :schools, :school_id, :name => 'by_school_id'
  end
  
  def down
    drop_index 'by_zipcode'
    drop_index 'by_state'
    drop_index 'by_city'
    drop_index 'by_school_id'
    
    drop_table :schools
  end
end
