class Barcode < ActiveRecord::Base
  attr_accessible :barcode, :times, :product_id
  belongs_to :product
end
