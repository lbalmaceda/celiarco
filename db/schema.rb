# encoding: UTF-8
# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended to check this file into your version control system.

ActiveRecord::Schema.define(:version => 20141004200615) do

  create_table "products", :force => true do |t|
    t.text     "name"
    t.text     "description"
    t.string   "rnpa"
    t.string   "barcode"
    t.boolean  "gluten_free"
    t.date     "down_date"
    t.text     "cause"
    t.datetime "created_at",  :null => false
    t.datetime "updated_at",  :null => false
  end

  add_index "products", ["rnpa"], :name => "index_products_on_rnpa", :unique => true

end
