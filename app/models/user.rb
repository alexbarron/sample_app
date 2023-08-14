class User < ApplicationRecord
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
    
end
