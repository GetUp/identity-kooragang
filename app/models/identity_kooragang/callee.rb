module IdentityKooragang
  class Callee < ReadWrite
    include ConnectionExtension
    self.table_name = "callees"
    belongs_to :campaign
    validates_uniqueness_of :phone_number, scope: :campaign

    def self.add_members(member_set)
      write_result = bulk_create(member_set)
      write_result_length = write_result ? write_result.cmd_tuples : 0
      if write_result_length != member_set.count
        Notify.warning("Kooragang Insert: Some Rows Duplicate and Ignored", "Only #{write_result_length} out of #{member_set.count} members were inserted. #{member_set.inspect}")
      end
      write_result_length
    end
  end
end
