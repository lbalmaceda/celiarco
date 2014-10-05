class CreateProducts < ActiveRecord::Migration
  def change
    create_table :products do |t|
      t.text :name
      t.text :description
      t.string :rnpa
      t.string :barcode
      t.boolean :gluten_free
      t.date :down_date
      t.text :cause

      t.timestamps
    end
    add_index :products, :rnpa, :unique => true
  end
end
