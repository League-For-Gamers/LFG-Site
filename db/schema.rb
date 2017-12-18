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

ActiveRecord::Schema.define(version: 20161114165221) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"
  enable_extension "hstore"

  create_table "bans", id: :serial, force: :cascade do |t|
    t.integer "user_id"
    t.integer "post_id"
    t.integer "role_id"
    t.string "reason"
    t.date "end_date"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "group_id"
    t.text "group_role"
    t.string "duration_string"
    t.integer "banner_id"
    t.index ["group_id"], name: "index_bans_on_group_id"
    t.index ["post_id"], name: "index_bans_on_post_id"
    t.index ["role_id"], name: "index_bans_on_role_id"
    t.index ["user_id"], name: "index_bans_on_user_id"
  end

  create_table "chats", id: :serial, force: :cascade do |t|
    t.string "key"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "chats_users", id: false, force: :cascade do |t|
    t.bigint "chat_id", null: false
    t.bigint "user_id", null: false
    t.datetime "last_read", default: -> { "now()" }
    t.index ["user_id", "chat_id"], name: "index_chats_users_on_user_id_and_chat_id", unique: true
  end

  create_table "follows", id: :serial, force: :cascade do |t|
    t.integer "user_id"
    t.integer "following_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["following_id"], name: "index_follows_on_following_id"
    t.index ["user_id"], name: "index_follows_on_user_id"
  end

  create_table "games", id: :serial, force: :cascade do |t|
    t.string "name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "boxart_file_name"
    t.string "boxart_content_type"
    t.integer "boxart_file_size"
    t.datetime "boxart_updated_at"
    t.index ["name"], name: "index_games_on_name", unique: true
  end

  create_table "games_users", id: false, force: :cascade do |t|
    t.bigint "game_id", null: false
    t.bigint "user_id", null: false
    t.index ["user_id", "game_id"], name: "index_games_users_on_user_id_and_game_id", unique: true
  end

  create_table "group_memberships", id: :serial, force: :cascade do |t|
    t.integer "group_id"
    t.integer "user_id"
    t.integer "role", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["group_id"], name: "index_group_memberships_on_group_id"
    t.index ["user_id"], name: "index_group_memberships_on_user_id"
  end

  create_table "groups", id: :serial, force: :cascade do |t|
    t.string "title", limit: 100, null: false
    t.string "slug", limit: 100, null: false
    t.string "description", limit: 1000
    t.integer "privacy", default: 0, null: false
    t.integer "comment_privacy", default: 0, null: false
    t.integer "membership", default: 0, null: false
    t.string "banner_file_name"
    t.string "banner_content_type"
    t.integer "banner_file_size"
    t.datetime "banner_updated_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "membership_count"
    t.boolean "official", default: false
    t.integer "post_control", default: 0
    t.integer "language", default: 0
    t.index ["slug"], name: "index_groups_on_slug"
  end

  create_table "notifications", id: :serial, force: :cascade do |t|
    t.integer "variant", null: false
    t.hstore "data", default: {}, null: false
    t.boolean "read", default: false, null: false
    t.integer "group_id"
    t.integer "user_id", null: false
    t.integer "post_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["group_id"], name: "index_notifications_on_group_id"
    t.index ["post_id"], name: "index_notifications_on_post_id"
    t.index ["user_id", "post_id", "group_id"], name: "index_notifications_on_user_id_and_post_id_and_group_id"
    t.index ["user_id", "post_id"], name: "index_notifications_on_user_id_and_post_id"
    t.index ["user_id", "variant"], name: "index_notifications_on_user_id_and_variant"
    t.index ["user_id"], name: "index_notifications_on_user_id"
  end

  create_table "pg_search_documents", id: :serial, force: :cascade do |t|
    t.text "content"
    t.string "searchable_type"
    t.integer "searchable_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["searchable_type", "searchable_id"], name: "index_pg_search_documents_on_searchable_type_and_searchable_id"
  end

  create_table "posts", id: :serial, force: :cascade do |t|
    t.text "body"
    t.integer "user_id"
    t.boolean "official"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "group_id"
    t.integer "parent_id"
    t.integer "children_count", default: 0, null: false
    t.hstore "extra_data", default: {}
    t.datetime "extra_data_date"
    t.index ["group_id"], name: "index_posts_on_group_id"
    t.index ["user_id"], name: "index_posts_on_user_id"
  end

  create_table "private_messages", id: :serial, force: :cascade do |t|
    t.integer "user_id"
    t.integer "chat_id"
    t.binary "body"
    t.binary "iv"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["chat_id"], name: "index_private_messages_on_chat_id"
    t.index ["user_id"], name: "index_private_messages_on_user_id"
  end

  create_table "roles", id: :serial, force: :cascade do |t|
    t.string "name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "skills", id: :serial, force: :cascade do |t|
    t.integer "category"
    t.integer "user_id"
    t.integer "confidence"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "note"
    t.index ["user_id"], name: "index_skills_on_user_id"
  end

  create_table "tags", id: :serial, force: :cascade do |t|
    t.string "name"
    t.integer "user_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id"], name: "index_tags_on_user_id"
  end

  create_table "users", id: :serial, force: :cascade do |t|
    t.string "username"
    t.string "password_digest"
    t.string "display_name"
    t.text "bio"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.binary "email"
    t.binary "email_iv"
    t.string "avatar_file_name"
    t.string "avatar_content_type"
    t.integer "avatar_file_size"
    t.datetime "avatar_updated_at"
    t.string "hashed_email"
    t.hstore "social", default: {}, null: false
    t.text "skill_notes"
    t.integer "skill_status"
    t.hstore "hidden", default: {}, null: false
    t.integer "role_id"
    t.string "verification_digest"
    t.datetime "verification_active"
    t.string "enc_key"
    t.integer "unread_count", default: 0
    t.index ["role_id"], name: "index_users_on_role_id"
  end

  add_foreign_key "bans", "groups"
  add_foreign_key "bans", "posts"
  add_foreign_key "bans", "users"
  add_foreign_key "follows", "users"
  add_foreign_key "follows", "users", column: "following_id"
  add_foreign_key "group_memberships", "groups"
  add_foreign_key "group_memberships", "users"
  add_foreign_key "notifications", "groups"
  add_foreign_key "notifications", "posts"
  add_foreign_key "notifications", "users"
  add_foreign_key "posts", "groups"
  add_foreign_key "posts", "users"
  add_foreign_key "private_messages", "chats"
  add_foreign_key "private_messages", "users"
  add_foreign_key "skills", "users"
  add_foreign_key "tags", "users"
  add_foreign_key "users", "roles"
end
