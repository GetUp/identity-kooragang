# == Schema Information
#
# Table name: organise.zips
#
#  id          :integer          not null
#  zip         :text
#  pcon_new    :text
#  eer         :integer
#  latitude    :float
#  longitude   :float
#  ccg         :text
#  ward_ons    :text
#  county_ons  :text
#  council     :text
#  gss_spc     :text
#  gss_spr     :text
#  retired     :boolean
#  gss_ward    :text
#  gss_county  :text
#  gss_council :text
#  created_at  :timestamp
#  updated_at  :timestamp
#

class Postcode < ApplicationRecord
  if Settings.databases.zip_schema
    self.table_name = "#{Settings.databases.zip_schema}.zips"
  end
  if Settings.databases.zip_primary_key
    self.primary_key = Settings.databases.zip_primary_key
  end

  def self.nearest_postcode(latitude, longitude)
    longitude = ApplicationRecord.connection.quote(longitude)
    latitude = ApplicationRecord.connection.quote(latitude)
    where("ST_Intersects(geom, ST_Buffer(ST_GeomFromText('POINT(#{longitude} #{latitude})', 4326), 0.05))").take(1).first
  end

  def zip
    self.id
  end

  def self.search(zip)
    zip ||= ''
    cleaned_zip = zip.strip.upcase.gsub(/[^0-9a-z-]/i, '')
    unless Settings.geography.postcode_dash
      cleaned_zip = cleaned_zip.delete('-')
    end
    find_by(self.primary_key => cleaned_zip)
  end

  def outcode
    zip.reverse[3..-1].reverse
  end
end
