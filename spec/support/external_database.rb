require 'active_record'
require_relative 'kooragang_test_schema'

module ExternalDatabaseHelpers
  class << self
    def set_external_database_urls(database_url)
      ENV['IDENTITY_DATABASE_URL'] = database_url
      ENV['IDENTITY_READ_ONLY_DATABASE_URL'] = database_url
      ENV['KOORAGANG_DATABASE_URL'] = replace_db_name_in_db_url(database_url, 'identity_kooragang_test_client_engine')
      ENV['KOORAGANG_READ_ONLY_DATABASE_URL'] = replace_db_name_in_db_url(database_url, 'identity_kooragang_test_client_engine')
    end

    def replace_db_name_in_db_url(database_url, replacement_db_name)
      return database_url.split('/')[0..-2].join('/') + '/' + replacement_db_name
    end

    def setup
      ExternalDatabaseHelpers.create_database
    ensure
      ActiveRecord::Base.establish_connection ENV['IDENTITY_DATABASE_URL']
    end

    def create_database
      puts 'Rebuilding test database for Kooragang...'

      kooragang_db = ENV['KOORAGANG_DATABASE_URL'].split('/').last
      ActiveRecord::Base.connection.execute("DROP DATABASE IF EXISTS #{kooragang_db};")
      ActiveRecord::Base.connection.execute("CREATE DATABASE #{kooragang_db};")
      ActiveRecord::Base.establish_connection ENV['KOORAGANG_DATABASE_URL']
      CreateKooragangTestDb.new.up
    end

    def clean
      AreaMembership.all.destroy_all
      Area.all.destroy_all
      Address.all.destroy_all
      PhoneNumber.all.destroy_all
      ListMember.all.destroy_all
      List.all.destroy_all
      Member.all.destroy_all
      Member.all.destroy_all
      MemberSubscription.all.destroy_all
      Subscription.all.destroy_all
      Contact.all.destroy_all
      ContactCampaign.all.destroy_all
      ContactResponseKey.all.destroy_all
      ContactResponse.all.destroy_all
      CustomField.all.destroy_all
      CustomFieldKey.all.destroy_all
      Search.all.destroy_all
      IdentityKooragang::Call.all.destroy_all
      IdentityKooragang::Callee.all.destroy_all
      IdentityKooragang::Campaign.all.destroy_all
      IdentityKooragang::Caller.all.destroy_all
      IdentityKooragang::SurveyResult.all.destroy_all
      IdentityKooragang::Audience.all.destroy_all
    end
  end
end
