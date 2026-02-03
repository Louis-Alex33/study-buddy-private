class AddAnnotationFieldsToNotes < ActiveRecord::Migration[7.1]
  def change
    add_column :notes, :selected_text, :text
    add_column :notes, :text_start, :integer
    add_column :notes, :text_end, :integer
    add_column :notes, :annotation_type, :string, default: "sidebar"
  end
end
