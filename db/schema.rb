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

ActiveRecord::Schema.define(:version => 20140902143851) do

  create_table "ads", :force => true do |t|
    t.integer  "job_id"
    t.integer  "board_id"
    t.datetime "created_at", :null => false
    t.datetime "updated_at", :null => false
  end

  add_index "ads", ["board_id"], :name => "index_ads_on_board_id"
  add_index "ads", ["job_id"], :name => "index_ads_on_job_id"

  create_table "ambassadors", :force => true do |t|
    t.string   "provider"
    t.string   "uid"
    t.integer  "employer_id"
    t.string   "email"
    t.string   "title"
    t.string   "first_name"
    t.string   "last_name"
    t.binary   "avatar"
    t.string   "avatar_content_type"
    t.integer  "status",              :default => 0
    t.datetime "created_at",                         :null => false
    t.datetime "updated_at",                         :null => false
    t.text     "profile_links_map"
    t.integer  "auth_id"
    t.datetime "reminder_sent_at"
  end

  add_index "ambassadors", ["employer_id"], :name => "index_ambassadors_on_employer_id"

  create_table "auths", :force => true do |t|
    t.string   "provider"
    t.string   "uid"
    t.string   "first_name"
    t.string   "last_name"
    t.string   "title"
    t.text     "profile_links_map"
    t.string   "email"
    t.binary   "avatar"
    t.string   "avatar_content_type"
    t.datetime "created_at",          :null => false
    t.datetime "updated_at",          :null => false
  end

  add_index "auths", ["email"], :name => "index_auths_on_email"
  add_index "auths", ["provider", "uid"], :name => "index_auths_on_provider_and_uid", :unique => true

  create_table "boards", :force => true do |t|
    t.string   "name"
    t.string   "title"
    t.text     "description"
    t.string   "tag"
    t.integer  "order"
    t.datetime "created_at",     :null => false
    t.datetime "updated_at",     :null => false
    t.string   "developer_text"
  end

  create_table "comments", :force => true do |t|
    t.text     "body"
    t.integer  "infointerview_id"
    t.integer  "created_by"
    t.integer  "ambassador_id"
    t.datetime "created_at",                      :null => false
    t.datetime "updated_at",                      :null => false
    t.integer  "status",           :default => 0
  end

  add_index "comments", ["infointerview_id"], :name => "index_comments_on_infointerview_id"

  create_table "company_ratings", :force => true do |t|
    t.integer  "user_id"
    t.string   "company_name"
    t.integer  "impact"
    t.integer  "worklife_balance"
    t.integer  "career_opportunitites"
    t.integer  "learning_opportunitites"
    t.integer  "workplace_perks"
    t.integer  "relaxed_culture"
    t.integer  "ace_colleagues"
    t.datetime "created_at",              :null => false
    t.datetime "updated_at",              :null => false
  end

  add_index "company_ratings", ["user_id"], :name => "index_company_ratings_on_user_id"

  create_table "employer_plans", :force => true do |t|
    t.integer  "tier"
    t.integer  "monthly_price"
    t.integer  "employer_id"
    t.datetime "created_at",    :null => false
    t.datetime "updated_at",    :null => false
  end

  add_index "employer_plans", ["employer_id"], :name => "index_employer_plans_on_employer_id"

  create_table "employers", :force => true do |t|
    t.string   "first_name"
    t.string   "last_name"
    t.string   "email"
    t.string   "li_url"
    t.string   "company_name"
    t.boolean  "sample"
    t.string   "password_digest"
    t.string   "remember_token"
    t.integer  "status",                    :default => 0
    t.datetime "created_at"
    t.datetime "updated_at"
    t.text     "join_us_widget_params_map"
    t.datetime "join_us_widget_heartbeat"
    t.string   "reminder_subject"
    t.text     "reminder_body"
    t.integer  "reminder_period",           :default => 0
    t.string   "invitation_subject"
    t.string   "invitation_salutation"
    t.text     "invitation_body"
    t.boolean  "enable_ping",               :default => true
  end

  add_index "employers", ["email"], :name => "index_employers_on_email", :unique => true
  add_index "employers", ["remember_token"], :name => "index_employers_on_remember_token"

  create_table "followups", :force => true do |t|
    t.integer  "status",           :default => 0
    t.integer  "ambassador_id"
    t.integer  "infointerview_id"
    t.datetime "created_at",                      :null => false
    t.datetime "updated_at",                      :null => false
  end

  add_index "followups", ["ambassador_id"], :name => "index_followups_on_ambassador_id"

  create_table "fyi_configurations", :force => true do |t|
    t.string   "key"
    t.string   "value"
    t.datetime "created_at", :null => false
    t.datetime "updated_at", :null => false
  end

  create_table "infointerviews", :force => true do |t|
    t.string   "email"
    t.string   "first_name"
    t.string   "last_name"
    t.integer  "job_id"
    t.integer  "user_id"
    t.text     "profiles"
    t.integer  "status",                      :default => 0
    t.datetime "created_at",                                     :null => false
    t.datetime "updated_at",                                     :null => false
    t.integer  "auth_id"
    t.integer  "referred_by"
    t.string   "resume_doc_id"
    t.boolean  "update_candidate_after_ping", :default => false
  end

  add_index "infointerviews", ["job_id"], :name => "index_infointerviews_on_job_id"

  create_table "interviews", :force => true do |t|
    t.integer  "employer_id"
    t.integer  "user_id"
    t.integer  "job_id"
    t.integer  "status",       :default => 0
    t.date     "starts_on"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "contact_info"
    t.datetime "contacted_at"
  end

  add_index "interviews", ["employer_id"], :name => "index_interviews_on_employer_id"
  add_index "interviews", ["job_id"], :name => "index_interviews_on_job_id"
  add_index "interviews", ["user_id"], :name => "index_interviews_on_user_id"

  create_table "job_qualifier_tags", :force => true do |t|
    t.string   "name"
    t.integer  "priority",   :default => 0
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "job_qualifier_tags", ["name"], :name => "index_job_qualifier_tags_on_name", :unique => true

  create_table "jobs", :force => true do |t|
    t.integer  "employer_id"
    t.integer  "position_id"
    t.text     "description"
    t.integer  "location_id"
    t.string   "company_name"
    t.integer  "status",                                                    :default => 0
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "locale",                                                    :default => "en"
    t.boolean  "allow_telecommuting",                                       :default => false
    t.boolean  "allow_relocation",                                          :default => false
    t.string   "ad_url"
    t.decimal  "northmost",                 :precision => 15, :scale => 12
    t.decimal  "southmost",                 :precision => 15, :scale => 12
    t.decimal  "westmost",                  :precision => 15, :scale => 12
    t.decimal  "eastmost",                  :precision => 15, :scale => 12
    t.integer  "invites_counter",                                           :default => 0
    t.integer  "display_order",                                             :default => 0
    t.text     "tech_stack_list",                                           :default => ""
    t.integer  "image_1_id"
    t.integer  "image_2_id"
    t.integer  "image_3_id"
    t.integer  "logo_image_id"
    t.string   "company_url"
    t.string   "address"
    t.decimal  "address_lat",               :precision => 15, :scale => 12
    t.decimal  "address_lng",               :precision => 15, :scale => 12
    t.text     "join_us_widget_params_map"
    t.string   "video_url"
    t.integer  "image_4_id"
    t.text     "benefits_list",                                             :default => ""
    t.datetime "published_at"
    t.text     "full_description"
    t.text     "share_title"
    t.text     "share_description"
    t.text     "share_short_description"
  end

  add_index "jobs", ["display_order"], :name => "index_jobs_on_display_order"
  add_index "jobs", ["eastmost"], :name => "index_jobs_on_eastmost"
  add_index "jobs", ["employer_id"], :name => "index_jobs_on_employer_id"
  add_index "jobs", ["locale"], :name => "index_jobs_on_locale"
  add_index "jobs", ["northmost"], :name => "index_jobs_on_northmost"
  add_index "jobs", ["southmost"], :name => "index_jobs_on_southmost"
  add_index "jobs", ["westmost"], :name => "index_jobs_on_westmost"

  create_table "location_tags", :force => true do |t|
    t.string   "name"
    t.integer  "priority",                                   :default => 0
    t.datetime "created_at"
    t.datetime "updated_at"
    t.decimal  "latitude",   :precision => 15, :scale => 12
    t.decimal  "longitude",  :precision => 15, :scale => 12
  end

  add_index "location_tags", ["name"], :name => "index_location_tags_on_name", :unique => true

  create_table "photos", :force => true do |t|
    t.string   "title"
    t.string   "image"
    t.integer  "bytes"
    t.integer  "crop_x"
    t.integer  "crop_y"
    t.integer  "crop_w"
    t.integer  "crop_h"
    t.datetime "created_at", :null => false
    t.datetime "updated_at", :null => false
    t.string   "image_set"
  end

  add_index "photos", ["image_set"], :name => "index_photos_on_image_set"

  create_table "position_tags", :force => true do |t|
    t.string   "name"
    t.integer  "priority",   :default => 0
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "family_id"
  end

  create_table "reminders", :force => true do |t|
    t.string   "recipient_type"
    t.integer  "user_id"
    t.integer  "employer_id"
    t.integer  "linked_object_id"
    t.string   "reminder_type"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "shares", :force => true do |t|
    t.integer  "ambassador_id"
    t.string   "network"
    t.integer  "click_counter", :default => 0
    t.datetime "created_at",                   :null => false
    t.datetime "updated_at",                   :null => false
    t.integer  "job_id"
    t.integer  "lead_counter",  :default => 0
    t.integer  "share_counter", :default => 0
    t.string   "ip"
    t.string   "referer"
  end

  add_index "shares", ["ambassador_id"], :name => "index_shares_on_ambassador_id"
  add_index "shares", ["job_id"], :name => "index_shares_on_job_id"
  add_index "shares", ["network"], :name => "index_shares_on_network"

  create_table "skill_tags", :force => true do |t|
    t.string   "name"
    t.integer  "priority",   :default => 0
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "skill_tags", ["name"], :name => "index_skill_tags_on_name", :unique => true

  create_table "user_job_qualifiers", :force => true do |t|
    t.integer  "job_qualifier_tag_id"
    t.integer  "user_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "user_skills", :force => true do |t|
    t.integer  "skill_tag_id"
    t.integer  "user_id"
    t.integer  "seniority"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "users", :force => true do |t|
    t.string   "first_name"
    t.string   "email"
    t.string   "password_digest"
    t.string   "remember_token"
    t.integer  "status",                                              :default => 0
    t.boolean  "admin",                                               :default => false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "current_position_id"
    t.integer  "wanted_position_id"
    t.integer  "wanted_salary",                                       :default => 0
    t.integer  "location_id"
    t.boolean  "sample"
    t.string   "free_text"
    t.string   "last_name"
    t.string   "contact_info"
    t.decimal  "northmost",           :precision => 15, :scale => 12
    t.decimal  "southmost",           :precision => 15, :scale => 12
    t.decimal  "westmost",            :precision => 15, :scale => 12
    t.decimal  "eastmost",            :precision => 15, :scale => 12
    t.text     "resume"
    t.string   "locale",                                              :default => "en"
    t.boolean  "double_bonus",                                        :default => false
    t.integer  "num_recommended",                                     :default => 0
    t.boolean  "can_relocate"
    t.boolean  "can_telecommute"
    t.integer  "aspiration"
    t.boolean  "ask_requirements",                                    :default => false
    t.boolean  "vouched",                                             :default => false
  end

  add_index "users", ["eastmost"], :name => "index_users_on_eastmost"
  add_index "users", ["email"], :name => "index_users_on_email", :unique => true
  add_index "users", ["locale"], :name => "index_users_on_locale"
  add_index "users", ["northmost"], :name => "index_users_on_northmost"
  add_index "users", ["remember_token"], :name => "index_users_on_remember_token"
  add_index "users", ["southmost"], :name => "index_users_on_southmost"
  add_index "users", ["westmost"], :name => "index_users_on_westmost"

end
