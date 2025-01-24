class CountListMembersWorker
  include Sidekiq::Worker
  sidekiq_options queue: 'critical'

  def perform(id)
    List.find(id).count_members
  end
end
