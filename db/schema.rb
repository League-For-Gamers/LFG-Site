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

ActiveRecord::Schema.define(version: 20151020231750) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"
  enable_extension "hstore"

  create_table "bans", force: :cascade do |t|
    t.integer  "user_id"
    t.integer  "post_id"
    t.integer  "role_id"
    t.string   "reason"
    t.date     "end_date"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer  "group_id"
    t.text     "group_role"
  end

  add_index "bans", ["group_id"], name: "index_bans_on_group_id", using: :btree
  add_index "bans", ["post_id"], name: "index_bans_on_post_id", using: :btree
  add_index "bans", ["role_id"], name: "index_bans_on_role_id", using: :btree
  add_index "bans", ["user_id"], name: "index_bans_on_user_id", using: :btree

  create_table "chats", force: :cascade do |t|
    t.string   "key"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "chats_users", id: false, force: :cascade do |t|
    t.integer  "chat_id",                     null: false
    t.integer  "user_id",                     null: false
    t.datetime "last_read", default: "now()"
  end

  add_index "chats_users", ["user_id", "chat_id"], name: "index_chats_users_on_user_id_and_chat_id", unique: true, using: :btree

  create_table "follows", force: :cascade do |t|
    t.integer  "user_id"
    t.integer  "following_id"
    t.datetime "created_at",   null: false
    t.datetime "updated_at",   null: false
  end

  add_index "follows", ["following_id"], name: "index_follows_on_following_id", using: :btree
  add_index "follows", ["user_id"], name: "index_follows_on_user_id", using: :btree

  create_table "games", force: :cascade do |t|
    t.string   "name"
    t.datetime "created_at",          null: false
    t.datetime "updated_at",          null: false
    t.string   "boxart_file_name"
    t.string   "boxart_content_type"
    t.integer  "boxart_file_size"
    t.datetime "boxart_updated_at"
  end

  add_index "games", ["name"], name: "index_games_on_name", unique: true, using: :btree

  create_table "games_users", id: false, force: :cascade do |t|
    t.integer "game_id", null: false
    t.integer "user_id", null: false
  end

  add_index "games_users", ["user_id", "game_id"], name: "index_games_users_on_user_id_and_game_id", unique: true, using: :btree

  create_table "group_memberships", force: :cascade do |t|
    t.integer  "group_id"
    t.integer  "user_id"
    t.integer  "role",       null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  add_index "group_memberships", ["group_id"], name: "index_group_memberships_on_group_id", using: :btree
  add_index "group_memberships", ["user_id"], name: "index_group_memberships_on_user_id", using: :btree

  create_table "groups", force: :cascade do |t|
    t.string   "title",               limit: 100,              null: false
    t.string   "slug",                limit: 100,              null: false
    t.string   "description",         limit: 1000
    t.integer  "privacy",                          default: 0, null: false
    t.integer  "comment_privacy",                  default: 0, null: false
    t.integer  "membership",                       default: 0, null: false
    t.string   "banner_file_name"
    t.string   "banner_content_type"
    t.integer  "banner_file_size"
    t.datetime "banner_updated_at"
    t.datetime "created_at",                                   null: false
    t.datetime "updated_at",                                   null: false
  end

  add_index "groups", ["slug"], name: "index_groups_on_slug", using: :btree

  create_table "permissions", force: :cascade do |t|
    t.string   "name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "permissions_roles", id: false, force: :cascade do |t|
    t.integer "permission_id", null: false
    t.integer "role_id",       null: false
  end

  add_index "permissions_roles", ["role_id", "permission_id"], name: "index_permissions_roles_on_role_id_and_permission_id", unique: true, using: :btree

  create_table "pg_search_documents", force: :cascade do |t|
    t.text     "content"
    t.integer  "searchable_id"
    t.string   "searchable_type"
    t.datetime "created_at",      null: false
    t.datetime "updated_at",      null: false
  end

  add_index "pg_search_documents", ["searchable_type", "searchable_id"], name: "index_pg_search_documents_on_searchable_type_and_searchable_id", using: :btree

  create_table "posts", force: :cascade do |t|
    t.text     "body"
    t.integer  "user_id"
    t.boolean  "official"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean  "pinned"
    t.integer  "group_id"
  end

  add_index "posts", ["group_id"], name: "index_posts_on_group_id", using: :btree
  add_index "posts", ["user_id"], name: "index_posts_on_user_id", using: :btree

  create_table "private_messages", force: :cascade do |t|
    t.integer  "user_id"
    t.integer  "chat_id"
    t.binary   "body"
    t.binary   "iv"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  add_index "private_messages", ["chat_id"], name: "index_private_messages_on_chat_id", using: :btree
  add_index "private_messages", ["user_id"], name: "index_private_messages_on_user_id", using: :btree

  create_table "roles", force: :cascade do |t|
    t.string   "name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "skills", force: :cascade do |t|
    t.integer  "category"
    t.integer  "user_id"
    t.integer  "confidence"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string   "note"
  end

  add_index "skills", ["user_id"], name: "index_skills_on_user_id", using: :btree

  create_table "tags", force: :cascade do |t|
    t.string   "name"
    t.integer  "user_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  add_index "tags", ["user_id"], name: "index_tags_on_user_id", using: :btree

  create_table "users", force: :cascade do |t|
    t.string   "username"
    t.string   "password_digest"
    t.string   "display_name"
    t.text     "bio"
    t.datetime "created_at",                       null: false
    t.datetime "updated_at",                       null: false
    t.binary   "email"
    t.binary   "email_iv"
    t.string   "avatar_file_name"
    t.string   "avatar_content_type"
    t.integer  "avatar_file_size"
    t.datetime "avatar_updated_at"
    t.string   "hashed_email"
    t.hstore   "social",              default: {}, null: false
    t.text     "skill_notes"
    t.integer  "skill_status"
    t.hstore   "hidden",              default: {}, null: false
    t.integer  "role_id"
    t.string   "verification_digest"
    t.datetime "verification_active"
    t.string   "enc_key"
    t.integer  "unread_count",        default: 0
  end

  add_index "users", ["role_id"], name: "index_users_on_role_id", using: :btree

  add_foreign_key "bans", "groups"
  add_foreign_key "bans", "posts"
  add_foreign_key "bans", "users"
  add_foreign_key "follows", "users"
  add_foreign_key "follows", "users", column: "following_id"
  add_foreign_key "group_memberships", "groups"
  add_foreign_key "group_memberships", "users"
  add_foreign_key "posts", "groups"
  add_foreign_key "posts", "users"
  add_foreign_key "private_messages", "chats"
  add_foreign_key "private_messages", "users"
  add_foreign_key "skills", "users"
  add_foreign_key "tags", "users"
  add_foreign_key "users", "roles"
end
