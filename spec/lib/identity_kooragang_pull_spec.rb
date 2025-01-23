require 'rails_helper'

describe IdentityKooragang do
  context '#pull' do
    before(:each) do
      @sync_id = 1
      @external_system_params = JSON.generate({'pull_job' => 'fetch_new_calls'})
    end

    context 'with valid parameters' do
      it 'should call the corresponding method'  do
        expect(IdentityKooragang).to receive(:fetch_new_calls).exactly(1).times.with(1)
        IdentityKooragang.pull(@sync_id, @external_system_params)
      end
    end
  end

  context '#fetch_new_calls' do

    before(:each) do
      $redis.reset

      @sync_id = 1
      @subscription = FactoryBot.create(:calling_subscription)
      Settings.stub_chain(:kooragang, :subscription_id) { @subscription.id }
      Settings.stub_chain(:kooragang, :push_batch_amount) { nil }
      Settings.stub_chain(:kooragang, :pull_batch_amount) { nil }

      @time = Time.now - 120.seconds
      @kooragang_campaign = FactoryBot.create(:kooragang_campaign)
      @team = FactoryBot.create(:kooragang_team)

      3.times do |n|
        callee = FactoryBot.create(:kooragang_callee, first_name: "Bob#{n}", phone_number: "6142770040#{n}", campaign: @kooragang_campaign)
        caller = FactoryBot.create(:kooragang_caller, first_name: "Jacob#{n}", phone_number: "6142770042#{n}", team: @team)
        call = FactoryBot.create(:kooragang_call, created_at: @time, callee: callee, caller: caller, ended_at: @time + 60.seconds, status: 'success')
        call.survey_results << FactoryBot.build(:kooragang_survey_result, question: 'disposition', answer: 'no answer')
        call.survey_results << FactoryBot.build(:kooragang_survey_result, question: 'voting_intention', answer: 'labor')
      end
    end

    it 'should fetch the new calls and insert them' do
      IdentityKooragang.fetch_new_calls(@sync_id) {}
      expect(Contact.count).to eq(3)
      member = Member.find_by_phone('61427700401')
      expect(member).to have_attributes(first_name: 'Bob1')
      expect(member.contacts_received.count).to eq(1)
      expect(member.contacts_made.count).to eq(0)
    end

    it 'should record all details' do
      IdentityKooragang.fetch_new_calls(@sync_id) {}
      expect(Contact.first).to have_attributes(duration: 60, system: 'kooragang', contact_type: 'call', status: 'success')
      expect(Contact.first.happened_at.utc.to_s).to eq(@time.utc.to_s)
    end

    it 'should record the team that the call was with' do
      IdentityKooragang.fetch_new_calls(@sync_id) {}
      expect(Contact.first.data['team']).to eq(@team.name)
    end

    it 'should opt out people that need it' do
      member = FactoryBot.create(:member, name: 'BobNo')
      member.update_phone_number('61427700409')
      member.subscribe_to(@subscription)

      callee = FactoryBot.create(:kooragang_callee, first_name: 'BobNo', phone_number: '61427700409', campaign: @kooragang_campaign)
      call = FactoryBot.create(:kooragang_call, created_at: @time, callee: callee, ended_at: @time + 60.seconds, status: 'success')
      call.survey_results << FactoryBot.build(:kooragang_survey_result, question: 'disposition', answer: 'do not call')

      IdentityKooragang.fetch_new_calls(@sync_id) {}

      member.reload
      expect(member.is_subscribed_to?(@subscription)).to eq(false)
    end

    it 'should assign a campaign' do
      IdentityKooragang.fetch_new_calls(@sync_id) {}
      expect(ContactCampaign.count).to eq(1)
      expect(ContactCampaign.first.contacts.count).to eq(3)
      expect(ContactCampaign.first).to have_attributes(name: @kooragang_campaign.name, external_id: @kooragang_campaign.id, system: 'kooragang', contact_type: 'call')
    end

    it 'should match members receiving calls' do
      member = FactoryBot.create(:member, first_name: 'Bob1')
      member.update_phone_number('61427700401')

      IdentityKooragang.fetch_new_calls(@sync_id) {}
      expect(member.contacts_received.count).to eq(1)
      expect(member.contacts_made.count).to eq(0)
    end

    it 'should match members making calls' do
      member = FactoryBot.create(:member, first_name: 'Jacob1')
      member.update_phone_number('61427700421')
      IdentityKooragang.fetch_new_calls(@sync_id) {}
      expect(member.contacts_received.count).to eq(0)
      expect(member.contacts_made.count).to eq(1)
    end

    it 'should upsert calls' do
      member = FactoryBot.create(:member, first_name: 'Janis')
      member.update_phone_number('61427700401')
      call = IdentityKooragang::Call.last
      FactoryBot.create(:contact, contactee: member, external_id: call.id)
      IdentityKooragang.fetch_new_calls(@sync_id) {}
      expect(Contact.count).to eq(3)
      expect(member.contacts_received.count).to eq(1)
    end

    it 'should be idempotent' do
      IdentityKooragang.fetch_new_calls(@sync_id) {}
      contact_hash = Contact.all.select('contactee_id, contactor_id, duration, system, contact_campaign_id').as_json
      expect {
        IdentityKooragang.fetch_new_calls(@sync_id, force: true) {}
      }.to_not change{ ContactResponse.count }
    end

    it 'should update the last_updated_at' do
      old_updated_at = $redis.with { |r| r.get 'kooragang:calls:last_updated_at' }
      sleep 2
      callee = FactoryBot.create(:kooragang_callee, first_name: 'BobNo', phone_number: '61427700408', campaign: @kooragang_campaign)
      call = FactoryBot.create(:kooragang_call, created_at: @time, callee: callee, ended_at: @time + 60.seconds, status: 'success')
      IdentityKooragang.fetch_new_calls(@sync_id) {}
      new_updated_at = $redis.with { |r| r.get 'kooragang:calls:last_updated_at' }

      expect(new_updated_at).not_to eq(old_updated_at)
    end

    it 'should correctly save Survey Results' do
      IdentityKooragang.fetch_new_calls(@sync_id) {}

      contact_response = ContactCampaign.last.contact_response_keys.find_by(key: 'voting_intention').contact_responses.first
      expect(contact_response.value).to eq('labor')
      expect(Contact.last.contact_responses.count).to eq(2)
    end

    it 'works if there is no caller' do
      callee = FactoryBot.create(:kooragang_callee, first_name: 'BobNo', phone_number: '61427700409', campaign: @kooragang_campaign)
      call = FactoryBot.create(:kooragang_call, created_at: @time, callee: callee, ended_at: @time + 60.seconds, status: 'success')
      IdentityKooragang.fetch_new_calls(@sync_id) {}
      expect(Contact.last.contactor).to be_nil
    end

    it 'works if there is no name' do
      callee = FactoryBot.create(:kooragang_callee, phone_number: '61427700409', campaign: @kooragang_campaign)
      call = FactoryBot.create(:kooragang_call, created_at: @time, callee: callee, ended_at: @time + 60.seconds, status: 'success')
      IdentityKooragang.fetch_new_calls(@sync_id) {}
      expect(Contact.last.contactee.phone).to eq('61427700409')
    end

    it "skips if callee phone can't be matched" do
      callee = FactoryBot.create(:kooragang_callee, phone_number: '6142709', campaign: @kooragang_campaign)
      call = FactoryBot.create(:kooragang_call, created_at: @time, callee: callee, ended_at: @time + 60.seconds, status: 'success')

      IdentityKooragang.fetch_new_calls(@sync_id) {}
      expect(Contact.count).to eq(3)
    end

    it "succeeds if caller phone can't be matched" do
      callee = FactoryBot.create(:kooragang_callee, phone_number: '61427700409', campaign: @kooragang_campaign)
      caller = FactoryBot.create(:kooragang_caller, phone_number: '6142409')
      call = FactoryBot.create(:kooragang_call, created_at: @time, callee: callee, caller: caller, ended_at: @time + 60.seconds, status: 'success')
      IdentityKooragang.fetch_new_calls(@sync_id) {}
      expect(Contact.count).to eq(4)
      expect(Contact.last.contactee.phone).to eq('61427700409')
      expect(Contact.last.contactor).to be_nil
    end

    context('with a campaign with an survey answer that is associated with an event id') do
      before do
        IdentityKooragang::Call.all.destroy_all
        member = FactoryBot.create(:member_with_mobile)
        campaign = FactoryBot.create(:kooragang_campaign_with_rsvp_questions)
        callee = FactoryBot.create(:kooragang_callee, phone_number: member.phone, campaign: campaign)
        caller = FactoryBot.create(:kooragang_caller, phone_number: '61427700429')
        call = FactoryBot.create(:kooragang_call, created_at: 2.minutes.ago, callee: callee, caller: caller, ended_at: Time.now, status: 'test')
        call.survey_results << IdentityKooragang::SurveyResult.new(question: 'rsvp', answer: 'going')
      end

      it 'should rsvp the member to the Nation Builder event when Nation Builder external service is active'  do
        expect(IdentityNationBuilder::API).to receive(:rsvp).exactly(1).times.with('stagingsite', anything, 1)
        IdentityKooragang.fetch_new_calls(@sync_id) {}
      end
    end

    context('with force=true passed as parameter') do
      before { IdentityKooragang::Call.update_all(updated_at: '1960-01-01 00:00:00') }

      it 'should ignore the last_updated_at and fetch all calls' do
        IdentityKooragang.fetch_new_calls(@sync_id, force: true) {}
        expect(Contact.count).to eq(3)
      end
    end

    context('with a campaign that has syncing set to false') do
      before do
        @kooragang_campaign.sync_to_identity = false
        @kooragang_campaign.save!
      end

      it 'should only find calls from campaigns where syncing is true' do
        kooragang_campaign_2 = FactoryBot.create(:kooragang_campaign)
        callee = FactoryBot.create(:kooragang_callee, first_name: "Bobby", phone_number: "61427700409", campaign: kooragang_campaign_2)
        caller = FactoryBot.create(:kooragang_caller, first_name: "Jacoby", phone_number: "61427700429")
        call = FactoryBot.create(:kooragang_call, created_at: @time, callee: callee, caller: caller, ended_at: @time + 60.seconds, status: 'success')
        call.survey_results << FactoryBot.build(:kooragang_survey_result, question: 'disposition', answer: 'no answer')
        call.survey_results << FactoryBot.build(:kooragang_survey_result, question: 'voting_intention', answer: 'labor')

        IdentityKooragang.fetch_new_calls(@sync_id) {}
        expect(Contact.count).to eq(1)
      end
    end
  end

  context '#fetch_current_campaigns' do

    before(:each) do
      @sync_id = 1
      2.times do
        FactoryBot.create(:kooragang_campaign_with_rsvp_questions, status: 'active')
      end
      FactoryBot.create(:kooragang_campaign_with_rsvp_questions, status: 'paused')
      FactoryBot.create(:kooragang_campaign_with_rsvp_questions, status: 'inactive')
    end

    it 'should create contact_campaigns' do
      IdentityKooragang.fetch_current_campaigns(@sync_id) {}
      expect(ContactCampaign.count).to eq(3)
      ContactCampaign.all.each do |campaign|
        expect(campaign).to have_attributes(
          system: IdentityKooragang::SYSTEM_NAME,
          contact_type: IdentityKooragang::CONTACT_TYPE
        )
      end
    end

    it 'should create contact_response_keys' do
      IdentityKooragang.fetch_current_campaigns(@sync_id) {}
      expect(ContactResponseKey.count).to eq(6)
      expect(ContactResponseKey.where(key: 'disposition').count).to eq(3)
      expect(ContactResponseKey.where(key: 'rsvp').count).to eq(3)
    end
  end
end

# Dummy engine module
module IdentityNationBuilder
  class API
    def self.rsvp(site_slug, member, event_id)
    end
  end
  class NationBuilderMemberSyncPushSerializer < ActiveModel::Serializer
  end
end
