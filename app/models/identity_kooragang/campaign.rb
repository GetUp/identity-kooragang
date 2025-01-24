module IdentityKooragang
  class Campaign < ReadOnly
    self.table_name = "campaigns"
    has_many :callees, dependent: nil
    has_many :audiences, dependent: nil

    ACTIVE_STATUS = 'active'.freeze
    INACTIVE_STATUS = 'inactive'.freeze

    scope :syncable, -> {
      where(sync_to_identity: true)
        .where.not(status: INACTIVE_STATUS)
        .order('created_at')
    }
  end
end
