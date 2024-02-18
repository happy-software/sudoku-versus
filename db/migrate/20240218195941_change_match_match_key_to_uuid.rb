class ChangeMatchMatchKeyToUuid < ActiveRecord::Migration[7.0]
  def up
    # Add a new column for UUID
    add_column :matches, :temp_uuid, :uuid

    # Update the new UUID column with UUIDs generated from existing strings
    Match.all.each do |record|
      record.update(temp_uuid: record.match_key)
    end

    # Remove the old string column
    remove_column :matches, :match_key

    # Rename the temporary UUID column to match the original column name
    rename_column :matches, :temp_uuid, :match_key
  end

  def down
    # Add a new column for the original string column
    add_column :matches, :temp_string, :string

    # Update the new string column with the original string values
    Match.all.each do |record|
      record.update(temp_string: record.match_key)
    end

    # Remove the UUID column
    remove_column :matches, :match_key

    # Rename the temporary string column to match the original column name
    rename_column :matches, :temp_string, :match_key
  end
end
