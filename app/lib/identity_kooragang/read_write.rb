module IdentityKooragang
  class ReadWrite < ApplicationRecord
    self.abstract_class = true
    db_url_str = set_db_pool_size(Settings.kooragang.database_url)
    establish_connection db_url_str if db_url_str
  end
end
