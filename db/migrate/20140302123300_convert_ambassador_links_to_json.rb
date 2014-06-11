class ConvertAmbassadorLinksToJson < ActiveRecord::Migration
  def up
    add_column :ambassadors, :profile_links_map, :text
   
    Ambassador.reset_column_information 

    ambassadors = Ambassador.all
    ambassadors.each do |a|
       a.profile_links_map = a.profile_links
       a.save
    end
    
    remove_column :ambassadors, :profile_links
  end

  def down
    add_column :ambassadors, :profile_links, :text
   
    Ambassador.reset_column_information 

    ambassadors = Ambassador.all
    ambassadors.each do |a|
       a.profile_links = a.profile_links_map
       a.save
    end
    
    remove_column :ambassadors, :profile_links_map
  end
end
