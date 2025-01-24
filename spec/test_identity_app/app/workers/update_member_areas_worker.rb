class UpdateMemberAreasWorker
  include Sidekiq::Worker
  sidekiq_options queue: 'low'

  def perform(id)
    # Member can get merged before the job is executed so we need to check they exist still
    Member.includes(:addresses, :areas).find(id).update_areas
  end
end
