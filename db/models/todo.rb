require 'active_record'

class Todo < ActiveRecord::Base
  belongs_to :project
  belongs_to :creator, class_name: 'User', foreign_key: :creator_id
  belongs_to :last_editor, class_name: 'User', foreign_key: :last_edit_id
end
