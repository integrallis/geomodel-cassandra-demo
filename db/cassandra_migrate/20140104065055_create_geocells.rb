class CreateGeocells < CassandraMigrations::Migration
  def up
    create_table :geocells, :primary_keys => :geocell do |t|
      t.string :geocell
      t.set :schools, :type => :uuid
    end
  end
  
  def down
    drop_table :geocells
  end
end
