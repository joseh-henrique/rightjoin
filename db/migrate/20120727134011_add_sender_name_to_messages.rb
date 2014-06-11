class AddSenderNameToMessages < ActiveRecord::Migration
  def change
    add_column :messages, :sender_first_name, :string
    add_column :messages, :sender_last_name, :string
  end
end
