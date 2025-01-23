class Initial < ActiveRecord::Migration[7.0]
  enable_extension "plpgsql"

  create_table "callees", force: :cascade do |t|
    t.datetime "created_at",                 default: "now()"
    t.datetime "updated_at",                 default: "now()"
    t.string   "external_id",    limit: 255
    t.string   "first_name",     limit: 255
    t.string   "phone_number",   limit: 255
    t.string   "location",       limit: 255
    t.string   "caller",         limit: 255
    t.datetime "last_called_at"
    t.integer  "campaign_id", limit: 8, null: false
    t.json     "data"
    t.text     "target_number"
    t.boolean  "callable", default: true
    t.integer  'audience_id', limit: 8
  end

  add_index "callees", ["last_called_at", "campaign_id"], name: "callees_last_called_at_campaign_id_index", using: :btree
  add_index 'callees', ['campaign_id', 'phone_number'], name: 'callees_campaign_id_phone_number_unique', unique: true, using: :btree

  create_table "callers", force: :cascade do |t|
    t.datetime "created_at",                        default: "now()"
    t.datetime "updated_at",                        default: "now()"
    t.string   "external_id",           limit: 255
    t.string   "first_name",            limit: 255
    t.string   "phone_number",          limit: 255
    t.string   "location",              limit: 255
    t.string   "status",                limit: 255
    t.string   "conference_member_id",  limit: 255
    t.datetime "last_phoned_at"
    t.boolean  "callback", default: false
    t.string   "call_uuid", limit: 255
    t.integer  "seconds_waiting", default: 0, null: false
    t.integer  "campaign_id"
    t.integer  "team_id"
    t.text     "inbound_phone_number"
    t.boolean  "created_from_incoming",             default: true
    t.boolean  "inbound_sip",                       default: false
  end

  add_index "callers", ["call_uuid"], name: "callers_call_uuid_index", using: :btree
  add_index "callers", ["status", "campaign_id"], name: "callers_status_campaign_id_index", using: :btree
  add_index "callers", ["status"], name: "callers_status_index", using: :btree
  add_index "callers", ["team_id"], name: "callers_team_id_index", using: :btree

  create_table "calls", force: :cascade do |t|
    t.integer  "log_id", limit: 8
    t.integer  "caller_id"
    t.integer  "callee_id"
    t.datetime "created_at",                   default: "now()"
    t.datetime "updated_at",                   default: "now()"
    t.datetime "connected_at"
    t.datetime "ended_at"
    t.string   "status", limit: 255
    t.boolean  "dropped", default: false
    t.string   "callee_call_uuid", limit: 255
    t.string   "conference_uuid",  limit: 255
    t.integer  "duration"
  end

  add_index "calls", ["callee_call_uuid"], name: "calls_callee_call_uuid_index", using: :btree
  add_index "calls", ["conference_uuid"], name: "calls_conference_uuid_index", using: :btree
  add_index "calls", ["ended_at"], name: "calls_ended_at_index", using: :btree

  create_table "campaigns", force: :cascade do |t|
    t.datetime "created_at",                                                           default: "now()"
    t.datetime "updated_at",                                                           default: "now()"
    t.string   "name",                             limit: 255, null: false
    t.string   "status",                           limit: 255
    t.string   "dialer",                           limit: 255
    t.string   "script_url",                       limit: 255
    t.string   "phone_number",                     limit: 255
    t.decimal  "max_ratio",                                    precision: 8, scale: 2, default: 1.0
    t.decimal  "ratio",                                        precision: 8, scale: 2, default: 1.0
    t.datetime "last_checked_ratio_at"
    t.string   "ended_at", limit: 255
    t.boolean  "detect_answering_machine",                                             default: false
    t.decimal  "acceptable_drop_rate",                         precision: 8, scale: 2, default: 0.0
    t.decimal  "ratio_increment",                              precision: 8, scale: 2, default: 0.2
    t.integer  "ratio_window",                                                         default: 600
    t.integer  "recalculate_ratio_window",                                             default: 180
    t.integer  "calls_in_progress",                                                    default: 0,                                                                                                                                                                                                                                                                                                                                                                                           null: false
    t.json     "questions",                                                            default: {},                                                                                                                                                                                                                                                                                                                                                                                          null: false
    t.json     "more_info",                                                            default: {},                                                                                                                                                                                                                                                                                                                                                                                          null: false
    t.string   "ratio_decrease_factor",            limit: 255,                         default: "2",                                                                                                                                                                                                                                                                                                                                                                                         null: false
    t.string   "passcode",                         limit: 255
    t.string   "sms_number",                       limit: 255
    t.integer  "max_call_attempts",                                                    default: 1,                                                                                                                                                                                                                                                                                                                                                                                           null: false
    t.integer  "no_call_window",                                                       default: 240,                                                                                                                                                                                                                                                                                                                                                                                         null: false
    t.boolean  "exhaust_callees_before_recycling",                                     default: true,                                                                                                                                                                                                                                                                                                                                                                                        null: false
    t.boolean  "teams",                                                                default: false
    t.string   "target_number",                    limit: 255
    t.string   "redirect_number",                  limit: 255
    t.boolean  "transfer_to_target", default: false
    t.string   "number_region", limit: 255
    t.boolean  "hud",                                                                  default: false, null: false
    t.json     "hours_of_operation",                                                   default: { "monday" => { "start" => "09:00:00", "stop" => "20:20:00" }, "tuesday" => { "start" => "09:00:00", "stop" => "20:20:00" }, "wednesday" => { "start" => "09:00:00", "stop" => "20:20:00" }, "thursday" => { "start" => "09:00:00", "stop" => "20:20:00" }, "friday" => { "start" => "09:00:00", "stop" => "20:20:00" }, "saturday" => { "start" => "09:00:00", "stop" => "17:00:00" }, "sunday" => { "start" => "09:00:00", "stop" => "17:00:00" } }
    t.text     "hours_of_operation_timezone"
    t.integer  "min_callers_for_ratio", default: 5, null: false
    t.string   "outgoing_number", limit: 255
    t.boolean  "log_no_calls", default: false, null: false
    t.text     "hold_music", array: true
    t.boolean  "revert_to_redundancy", default: false
    t.text     "shortcode"
    t.boolean  "sync_to_identity", default: true
  end

  add_index "campaigns", ["name"], name: "campaigns_name_index", using: :btree
  add_index "campaigns", ["shortcode"], name: "campaigns_shortcode_index", using: :btree
  add_index "campaigns", ["status"], name: "campaigns_status_index", using: :btree

  create_table "events", force: :cascade do |t|
    t.datetime "created_at",              default: "now()"
    t.datetime "updated_at",              default: "now()"
    t.string   "name", limit: 255, null: false
    t.text     "value"
    t.integer  "campaign_id", limit: 8
    t.integer  "call_id",     limit: 8
    t.integer  "caller_id"
  end

  add_index "events", ["created_at", "name"], name: "events_created_at_name_index", using: :btree

  create_table "knex_migrations", force: :cascade do |t|
    t.string   "name", limit: 255
    t.integer  "batch"
    t.datetime "migration_time"
  end

  create_table "knex_migrations_lock", id: false, force: :cascade do |t|
    t.integer "is_locked"
  end

  create_table "logs", id: :bigserial, force: :cascade do |t|
    t.datetime "created_at", default: "now()"
    t.string   "UUID",       limit: 255
    t.string   "url",        limit: 255
    t.json     "body"
    t.json     "query"
    t.json     "params"
    t.json     "headers"
  end

  create_table "redirects", id: :bigserial, force: :cascade do |t|
    t.datetime "created_at", default: "now()"
    t.string   "call_uuid",       limit: 255
    t.integer  "campaign_id",     limit: 8, null: false
    t.integer  "callee_id",       limit: 8
    t.string   "phone_number",    limit: 255
    t.string   "redirect_number", limit: 255
    t.string   "target_number",   limit: 255
  end

  add_index "redirects", ["campaign_id"], name: "redirects_campaign_id_index", using: :btree

  create_table "survey_results", force: :cascade do |t|
    t.integer  "log_id", limit: 8
    t.datetime "created_at",             default: "now()"
    t.datetime "updated_at",             default: "now()"
    t.integer  "call_id",    limit: 8
    t.string   "question",   limit: 255
    t.string   "answer",     limit: 255
  end

  create_table "teams", force: :cascade do |t|
    t.string   "name",                limit: 255
    t.string   "passcode",            limit: 255
    t.datetime "last_user_joined_at"
    t.datetime "created_at",                      default: "now()"
    t.datetime "updated_at",                      default: "now()"
  end

  add_index "teams", ["name"], name: "teams_name_unique", unique: true, using: :btree
  add_index "teams", ["passcode"], name: "teams_passcode_unique", unique: true, using: :btree

  create_table "users", force: :cascade do |t|
    t.string   "phone_number", limit: 255
    t.integer  "team_id"
    t.datetime "last_joined_at"
    t.datetime "created_at",                 default: "now()"
    t.datetime "updated_at",                 default: "now()"
  end

  create_table 'audiences', force: true do |t|
    t.integer  'sync_id', limit: 8
    t.integer  'campaign_id', limit: 8
    t.integer  "priority",    limit: 8, default: 1
    t.string   'status', default: "initialising"
    t.datetime 'updated_at', default: 'now()'
  end
  execute "ALTER TABLE audiences ADD CONSTRAINT audiences_sync_id_campaign_id_unique UNIQUE (sync_id, campaign_id)"

  add_index "users", ["phone_number"], name: "users_phone_number_unique", unique: true, using: :btree

  add_foreign_key "callees", "campaigns", name: "callees_campaign_id_foreign"
  add_foreign_key "callers", "campaigns", name: "callers_campaign_id_foreign"
  add_foreign_key "callers", "teams", name: "callers_team_id_foreign"
  add_foreign_key "calls", "callees", name: "calls_callee_id_foreign"
  add_foreign_key "calls", "callers", name: "calls_caller_id_foreign"
  add_foreign_key "calls", "logs", name: "calls_log_id_foreign"
  add_foreign_key "events", "calls", name: "events_call_id_foreign"
  add_foreign_key "events", "campaigns", name: "events_campaign_id_foreign"
  add_foreign_key "redirects", "callees", name: "redirects_callee_id_foreign"
  add_foreign_key "redirects", "campaigns", name: "redirects_campaign_id_foreign"
  add_foreign_key "survey_results", "logs", name: "survey_results_log_id_foreign"
  add_foreign_key "users", "teams", name: "users_team_id_foreign"
end
