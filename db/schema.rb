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

ActiveRecord::Schema.define(version: 20160429064506) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"
  enable_extension "citext"

  create_table "agpay", id: false, force: :cascade do |t|
    t.citext  "employee_id"
    t.citext  "name"
    t.citext  "ssn"
    t.date    "day"
    t.citext  "class"
    t.citext  "unknown1"
    t.citext  "crop"
    t.citext  "unknown2"
    t.citext  "task"
    t.citext  "type"
    t.citext  "ranch"
    t.citext  "crew"
    t.decimal "rate",        precision: 8, scale: 2
    t.decimal "pieces",      precision: 8, scale: 2
    t.decimal "hours",       precision: 8, scale: 2
    t.decimal "amount",      precision: 8, scale: 2
  end

  add_index "agpay", ["employee_id", "day"], name: "agpay_key", using: :btree

  create_table "old_time_entries", force: :cascade do |t|
    t.citext  "employee_id",                             null: false
    t.date    "pay_day"
    t.date    "day"
    t.citext  "ssn"
    t.citext  "name"
    t.decimal "rate",            precision: 8, scale: 2
    t.decimal "pieces",          precision: 8, scale: 2
    t.decimal "hours",           precision: 8, scale: 2
    t.decimal "amount",          precision: 8, scale: 2
    t.time    "start_time"
    t.time    "end_time"
    t.time    "meal_start_time"
    t.time    "meal_end_time"
    t.decimal "timecard_rate",   precision: 8, scale: 2
    t.decimal "timecard_pieces", precision: 8, scale: 2
    t.decimal "timecard_hours",  precision: 8, scale: 2
    t.decimal "timecard_amount", precision: 8, scale: 2
    t.boolean "audited"
  end

  create_table "pay_periods", force: :cascade do |t|
    t.date "start_day"
    t.date "end_day"
    t.time "start_time"
    t.time "end_time"
    t.time "meal_start_time"
    t.time "meal_end_time"
  end

  create_table "time_entries", id: false, force: :cascade do |t|
    t.integer "id",                                      default: "nextval('time_entries_id_seq'::regclass)", null: false
    t.citext  "employee_id",                                                                                  null: false
    t.date    "pay_day"
    t.date    "day"
    t.citext  "ssn"
    t.citext  "name"
    t.decimal "rate",            precision: 8, scale: 2
    t.decimal "pieces",          precision: 8, scale: 2
    t.decimal "hours",           precision: 8, scale: 2
    t.decimal "amount",          precision: 8, scale: 2
    t.decimal "timecard_rate",   precision: 8, scale: 2
    t.decimal "timecard_pieces", precision: 8, scale: 2
    t.decimal "timecard_hours",  precision: 8, scale: 2
    t.decimal "timecard_amount", precision: 8, scale: 2
    t.time    "start_time"
    t.time    "end_time"
    t.time    "meal_start_time"
    t.time    "meal_end_time"
    t.boolean "audited"
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

  add_foreign_key "old_time_entries", "pay_periods", column: "pay_day", name: "time_entries_pay_period_fkey", on_delete: :nullify
  add_foreign_key "time_entries_activities", "old_time_entries", column: "time_entries_id", name: "time_entries_activities_time_entries_id_fkey", on_delete: :cascade
end
