class AddCustomMessagesToQuizPublishers < ActiveRecord::Migration
  def change
    add_column :quiz_publishers, :welcome_flash_message, :string
    add_column :quiz_publishers, :register_message, :string
  end
end
