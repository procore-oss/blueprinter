class User < ApplicationRecord
  attr_accessor :company, :description, :position
  has_many :vehicles
end
