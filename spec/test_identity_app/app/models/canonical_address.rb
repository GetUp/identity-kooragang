class CanonicalAddress < ApplicationRecord
  has_many :addresses
  has_and_belongs_to_many :areas

  before_save do
    self.search_text = [line1, line2, suburb, town, state, postcode, country].join(', ')
  end

  alias_attribute :zip, :postcode

  class << self
    def search(address = {})
      # There's no point looking for an empty address
      return nil if address.blank?

      # Handling for places such as Ireland, where a postcode can designate a single address
      if address[:postcode].present?
        pc_ca = CanonicalAddress.where(postcode: address[:postcode].to_s.upcase.delete(' '))
        # This is a bit awkward, but works around a Postgres bug with using COUNT against GIST
        # indices in need of a VACUUM FULL.
        return pc_ca.first if pc_ca.first && pc_ca.second.blank?
      end

      # Otherwise, we need at least a line1, line2, or a town/suburb to find the address
      if address.slice(:line1, :line2, :suburb, :town).values.any?(&:present?)
        address_string = [
          address[:line1],
          address[:line2],
          address[:suburb],
          address[:town],
          address[:state],
          address[:postcode],
          address[:country]
        ].join(', ').upcase

        core_schema = ApplicationRecord.connection.quote_table_name(Settings.databases.extensions_schemas.core)
        quoted_addr = ApplicationRecord.connection.quote(address_string)
        query = CanonicalAddress.where('search_text % ?', address_string)
                                .order('similarity DESC')
                                .select(Arel.sql("*, #{core_schema}.similarity(search_text, #{quoted_addr}) as similarity"))

        if address[:postcode].present?
          query = query.where(postcode: address[:postcode].to_s.upcase.delete(' '))
        end
        ca = query.first
        return ca if ca && ca.similarity > 0.7
      end

      # If we don't have a canonical address at this point, the search has failed
      nil
    end
  end
end
