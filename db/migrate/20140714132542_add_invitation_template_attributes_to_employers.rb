class AddInvitationTemplateAttributesToEmployers < ActiveRecord::Migration
  def change
    add_column :employers, :invitation_subject, :string
    add_column :employers, :invitation_salutation, :string
    add_column :employers, :invitation_body, :text
  end
end
