class RemoveFreeTextFromInfointerviews < ActiveRecord::Migration
  def change
    remove_column :infointerviews, :free_text
  end
end
