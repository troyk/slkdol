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
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 20160425231854) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"
  enable_extension "citext"

  create_table "time_entries", force: :cascade do |t|
    t.integer  "employee_id",                             null: false
    t.date     "pay_day"
    t.date     "day"
    t.citext   "ssn"
    t.citext   "name"
    t.decimal  "rate",            precision: 8, scale: 2
    t.decimal  "pieces",          precision: 8, scale: 2
    t.decimal  "hours",           precision: 8, scale: 2
    t.decimal  "amount",          precision: 8, scale: 2
    t.datetime "start_time"
    t.datetime "end_time"
    t.datetime "meal_start_time"
    t.datetime "meal_end_time"
  end

  add_index "time_entries", ["day"], name: "time_entries_day_key", using: :btree
  add_index "time_entries", ["employee_id"], name: "time_entries_employee_id_key", using: :btree
  add_index "time_entries", ["pay_day"], name: "time_entries_pay_day_key", using: :btree

  create_table "time_entries_activities", id: false, force: :cascade do |t|
    t.integer  "id",              default: "nextval('time_entries_activities_id_seq'::regclass)", null: false
    t.datetime "created_at",                                                                      null: false
    t.citext   "username",                                                                        null: false
    t.citext   "time_entries_id",                                                                 null: false
    t.jsonb    "data"
  end

  add_index "time_entries_activities", ["time_entries_id"], name: "time_entries_activities_fkey", using: :btree
  add_index "time_entries_activities", ["username"], name: "time_entries_activities_username_key", using: :btree

  add_foreign_key "time_entries_activities", "time_entries", column: "time_entries_id", name: "time_entries_activities_time_entries_id_fkey", on_delete: :cascade
end
