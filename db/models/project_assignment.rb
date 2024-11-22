require 'active_record'

class ProjectAssignment < ActiveRecord::Base
  belongs_to :user
  belongs_to :project
end
