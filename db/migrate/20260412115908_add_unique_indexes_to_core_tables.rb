class AddUniqueIndexesToCoreTables < ActiveRecord::Migration[8.0]
  def change
    add_index :users, :email, unique: true
    add_index :tags, :name, unique: true
    add_index :likes, [ :user_id, :post_id ], unique: true
    add_index :post_tags, [ :post_id, :tag_id ], unique: true
  end
end
