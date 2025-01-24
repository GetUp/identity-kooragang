module IdentityKooragang
  class Caller < ReadOnly
    self.table_name = "callers"
    has_many :calls, dependent: nil
    belongs_to :team, optional: true, class_name: 'IdentityKooragang::Team'
  end
end
