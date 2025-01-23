require 'rails_helper'

describe IdentityKooragang do
  before(:each) do
    @sync_id = 1
    @kooragang_campaign = FactoryBot.create(:kooragang_campaign)
    @external_system_params = JSON.generate({ 'campaign_id' => @kooragang_campaign.id, priority: '2', phone_type: 'mobile' })

    2.times { FactoryBot.create(:member_with_mobile) }
    FactoryBot.create(:member_with_landline)
    FactoryBot.create(:member)
  end

  context '#push' do
    before(:each) do
      @members = Member.all
    end

    context 'with valid parameters' do
      it 'has created an attributed Audience in Kooragang' do
        IdentityKooragang.push(@sync_id, @members, @external_system_params) do |_members_with_phone_numbers, _campaign_name|
          @kooragang_audience = IdentityKooragang::Audience.find_by(campaign_id: @kooragang_campaign.id)
          expect(@kooragang_audience).to have_attributes(campaign_id: @kooragang_campaign.id, sync_id: 1, status: 'initialising', priority: 2)
        end
      end
      it 'yeilds correct campaign_name' do
        IdentityKooragang.push(@sync_id, @members, @external_system_params) do |_members_with_phone_numbers, campaign_name|
          expect(campaign_name).to eq(@kooragang_campaign.name)
        end
      end
      it 'yeilds members_with_phone_numbers' do
        IdentityKooragang.push(@sync_id, @members, @external_system_params) do |members_with_phone_numbers, _campaign_name|
          expect(members_with_phone_numbers.count).to eq(2)
        end
      end
    end

    context 'with invalid priority parameters' do
      it 'has created an attributed Audience in Kooragang' do
        invalid_external_system_params = JSON.generate({ 'campaign_id' => @kooragang_campaign.id, priority: 'yada yada', phone_type: 'mobile' })
        IdentityKooragang.push(@sync_id, @members, invalid_external_system_params) do |_members_with_phone_numbers, _campaign_name|
          @kooragang_audience = IdentityKooragang::Audience.find_by(campaign_id: @kooragang_campaign.id)
          expect(@kooragang_audience).to have_attributes(campaign_id: @kooragang_campaign.id, sync_id: 1, status: 'initialising', priority: 1)
        end
      end
    end
  end

  context '#push_in_batches' do
    before(:each) do
      allow(Settings).to receive_message_chain("kooragang.push_batch_amount") { 10 }
      @members = Member.all.with_phone_type('mobile')
      @audience = FactoryBot.create(:kooragang_audience, sync_id: @sync_id, campaign_id: @kooragang_campaign.id, priority: 2)
    end

    context 'with valid parameters' do
      it 'updates attributed Audience in Kooragang' do
        IdentityKooragang.push_in_batches(1, @members, @external_system_params) do |_batch_index, _write_result_count|
          audience = IdentityKooragang::Audience.find_by(campaign_id: @kooragang_campaign.id)
          expect(audience).to have_attributes(status: 'active')
        end
      end
      it 'yeilds correct batch_index' do
        IdentityKooragang.push_in_batches(1, @members, @external_system_params) do |batch_index, _write_result_count|
          expect(batch_index).to eq(0)
        end
      end
      it 'yeilds write_result_count' do
        IdentityKooragang.push_in_batches(1, @members, @external_system_params) do |_batch_index, write_result_count|
          expect(write_result_count).to eq(2)
        end
      end
    end
  end
end
