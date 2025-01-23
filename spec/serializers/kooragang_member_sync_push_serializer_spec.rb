describe IdentityKooragang::KooragangMemberSyncPushSerializer do
  context 'serialize' do
    before(:each) do
      Settings.stub_chain(:kooragang) { {} }
      @sync_id = 1
      @kooragang_campaign = FactoryBot.create(:kooragang_campaign)
      @external_system_params = JSON.generate({ 'campaign_id' => @kooragang_campaign.id, priority: 2, phone_type: 'mobile' })
      @member = FactoryBot.create(:member_with_mobile_and_custom_fields)
      list = FactoryBot.create(:list)
      FactoryBot.create(:list_member, list: list, member: @member)
      FactoryBot.create(:member_with_mobile)
      FactoryBot.create(:member)
      @batch_members = Member.all.with_phone_numbers.in_batches.first
      @audience = IdentityKooragang::Audience.create!(sync_id: @sync_id, campaign_id: @kooragang_campaign.id)
    end

    it 'returns valid object' do
      rows = ActiveModel::Serializer::CollectionSerializer.new(
        @batch_members,
        serializer: IdentityKooragang::KooragangMemberSyncPushSerializer,
        audience_id: @audience.id,
        campaign_id: @kooragang_campaign.id,
        phone_type: 'mobile'
      ).as_json
      expect(rows.count).to eq(2)
      expect(rows[0][:external_id]).to eq(ListMember.first.member_id)
      expect(rows[0][:phone_number]).to eq(@member.phone)
      expect(rows[0][:campaign_id]).to eq(@kooragang_campaign.id)
      expect(rows[0][:audience_id]).to eq(@audience.id)
      data = JSON.parse(rows[0][:data])
      expect(data['address']).to eq(@member.address)
      expect(data['postcode']).to eq(@member.postcode)
    end

    it "only returns the most recently updated phone number" do
      @member.update_phone_number('61427700500', 'mobile')
      @member.update_phone_number('61427700600', 'mobile')
      @member.update_phone_number('61427700500', 'mobile')
      @batch_members = Member.all.with_phone_numbers.in_batches.first
      rows = ActiveModel::Serializer::CollectionSerializer.new(
        @batch_members,
        serializer: IdentityKooragang::KooragangMemberSyncPushSerializer,
        audience_id: @audience.id,
        campaign_id: @kooragang_campaign.id,
        phone_type: 'mobile'
      ).as_json
      expect(rows.first[:phone_number]).to eq('61427700500')
    end

    context 'with include_rsvped_events' do
      let!(:nationbuilder_id) { '2' }
      let!(:event_1) {
        Event.create!(
          name: 'test 1',
          start_time: 2.hours.since,
          location: 'location 1',
          data: { site_slug: "test", status: "published", path: "/test1", location: "test 1", start_time: "2019-04-10T11:00:00+11:00" }
        )
      }
      let!(:event_2) {
        Event.create!(
          name: 'test 2',
          start_time: 2.days.since,
          location: 'location 2',
          data: { site_slug: "test", status: "published", path: "/test2", start_time: "2019-04-11T11:00:00+10:00" }
        )
      }
      before do
        EventRsvp.create!(member_id: @member.id, event_id: event_1.id)
        EventRsvp.create!(member_id: @member.id, event_id: event_2.id)
        @member.member_external_ids.create!(system: 'nation_builder', external_id: nationbuilder_id)
      end

      it 'returns valid object' do
        rows = ActiveModel::Serializer::CollectionSerializer.new(
          [@member],
          serializer: IdentityKooragang::KooragangMemberSyncPushSerializer,
          audience_id: @audience.id,
          campaign_id: @kooragang_campaign.id,
          phone_type: 'mobile',
          include_rsvped_events: true
        ).as_json
        expect(rows[0][:external_id]).to eq(ListMember.first.member_id)
        data = JSON.parse(rows[0][:data])
        expect(data['nationbuilder_id']).to eq(nationbuilder_id)
        expect(data['upcoming_rsvps']).to match(/#{event_1.name}/)
        expect(data['upcoming_rsvps']).to match(/#{event_2.name}/)
      end
    end
  end
end
