class User < ApplicationRecord
    has_many :microposts, dependent: :destroy

    # users who are followers have active relationships with the followed user
    has_many :active_relationships, class_name: "Relationship", foreign_key: "follower_id", dependent: :destroy
    # selects users inner join on relationships.id  = users.id where follower_id = x
    # uses follower's user ID to find all users with a corresponding relationships record where the follower ID matches our user
    # source is necessary because otherwise Rails will look for "following_id"
    has_many :following, through: :active_relationships, source: :followed

    has_many :passive_relationships, class_name: "Relationship", foreign_key: "followed_id", dependent: :destroy
    # source is optional because Rails looks for follower_id automatically because it matches the attribute name
    has_many :followers, through: :passive_relationships, source: :follower 
    
    before_save { email.downcase! }
    validates :name, presence: true, length: { maximum: 50 }
    validates :email, 
        presence: true, 
        uniqueness: true,
        length: { maximum: 255 }, 
        format: { with: /\A[\w+\-.]+@[a-z\d\-.]+\.[a-z]+\z/i }
    has_secure_password
    validates :password, length: { minimum: 6 }, presence: true, allow_nil: true
    attr_accessor :remember_token

    
    def User.digest(string)
        cost = ActiveModel::SecurePassword.min_cost ? BCrypt::Engine::MIN_COST : BCrypt::Engine.cost
        BCrypt::Password.create(string, cost: cost)
    end

    def User.new_token
        SecureRandom.urlsafe_base64
    end

    # Remembers a user in the database for use in persistent sessions.
    def remember
        self.remember_token = User.new_token
        update_attribute(:remember_digest, User.digest(remember_token))
        remember_digest
    end

    # Returns a session token to prevent session hijacking.
    # We reuse the remember digest for convenience.
    def session_token
        remember_digest || remember
    end

    def forget
        update_attribute(:remember_digest, nil)
    end

    def authenticated?(remember_token)
        return false if remember_digest.nil?
        BCrypt::Password.new(remember_digest).is_password?(remember_token)
    end

    def feed
        following_ids = "SELECT followed_id FROM relationships WHERE follower_id = :user_id"
        Micropost.where("user_id IN (#{following_ids}) OR user_id = :user_id", user_id: id).includes(:user, image_attachment: :blob)
    end

    def follow(other_user)
        following << other_user unless self == other_user
    end

    def unfollow(other_user)
        following.delete(other_user)
    end

    def following?(other_user)
        following.include?(other_user)
    end
    
end
