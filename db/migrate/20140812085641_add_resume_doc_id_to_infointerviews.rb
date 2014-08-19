class AddResumeDocIdToInfointerviews < ActiveRecord::Migration
  def change
    add_column :infointerviews, :resume_doc_id, :string
  end
end
