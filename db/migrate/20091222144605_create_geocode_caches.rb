class CreateGeocodeCaches < ActiveRecord::Migration
  def self.up
    create_table :geocode_caches do |t|
      t.string  :location, :limit=>100
      t.decimal :lat, :precision => 15, :scale => 10
      t.decimal :lng, :precision => 15, :scale => 10

      t.timestamps
    end
    add_index :geocode_caches, :location, :unique => true
  end

  def self.down
    remove_index :geocode_caches, :location
    drop_table :geocode_caches
  end
end
