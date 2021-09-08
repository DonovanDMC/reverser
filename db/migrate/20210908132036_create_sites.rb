class CreateSites < ActiveRecord::Migration[6.1]
  def change
    create_table :sites do |t|
      t.string :internal_name, null: false, index: true
      t.string :display_name, null: false
      t.string :homepag, null: false
      t.string :artist_url_format, null: false
      t.string :artist_submission_format, null: false
      t.string :direct_url_format, null: false
      t.boolean :allows_hotlinking, null: false
      t.boolean :stores_original, null: false
      t.boolean :original_easily_accessible, null: false
      t.string :notes, null: false
      t.timestamps
    end
  end
end
