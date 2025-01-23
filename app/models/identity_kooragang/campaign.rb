module IdentityKooragang
  class Campaign < ReadOnly
    self.table_name = "campaigns"
    has_many :callees
    has_many :audiences

    ACTIVE_STATUS = 'active'
    INACTIVE_STATUS = 'inactive'

    scope :syncable, -> {
      where(sync_to_identity: true)
        .where.not(status: INACTIVE_STATUS)
        .order('created_at')
    }
  end
end
