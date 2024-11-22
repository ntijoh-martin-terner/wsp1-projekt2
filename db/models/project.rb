require 'active_record'

class Project < ActiveRecord::Base
  belongs_to :creator, class_name: 'User', foreign_key: :creator_id
  has_many :todos
  has_many :project_assignments
  has_many :users, through: :project_assignments
end
