class CreateBarcodes < ActiveRecord::Migration
  def change
    create_table :barcodes do |t|
      t.string :barcode
      t.integer :times
      t.integer :product_id
      t.timestamps
    end
  end
end
