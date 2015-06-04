class Status < ActiveRecord::Base
  has_many :comments, dependent: :destroy
  belongs_to :user

  validates :content , :presence => true,
                        :length => { minimum: 2 }

  validates :user_id, presence: true
end
