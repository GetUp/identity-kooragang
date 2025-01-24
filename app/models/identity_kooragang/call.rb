module IdentityKooragang
  class Call < ReadOnly
    self.table_name = "calls"
    belongs_to :callee
    belongs_to :caller, optional: true
    has_many :survey_results, dependent: nil
    delegate :campaign, to: :callee, allow_nil: true

    scope :updated_calls, ->(last_updated_at) {
      includes(:caller, { callee: [:campaign] }, :survey_results)
        .references(:campaign)
        .where('campaigns.sync_to_identity')
        .where('calls.ended_at is not null AND calls.callee_id is not null')
        .where('calls.updated_at > ?', last_updated_at)
        .order('calls.updated_at')
        .limit(Settings.kooragang.pull_batch_amount)
    }

    scope :updated_calls_all, ->(last_updated_at) {
      includes(:caller, { callee: [:campaign] }, :survey_results)
        .references(:campaign)
        .where('campaigns.sync_to_identity')
        .where('calls.ended_at is not null AND calls.callee_id is not null')
        .where('calls.updated_at > ?', last_updated_at)
        .order('calls.updated_at')
    }
  end
end
