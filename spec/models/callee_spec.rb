describe IdentityKooragang::Callee do
  context '#add_members' do
    before(:each) do
      @kooragang_campaign = FactoryBot.create(:kooragang_campaign)
      @member = FactoryBot.create(:member_with_mobile)
      @batch_members = Member.all
      @rows = ActiveModel::Serializer::CollectionSerializer.new(
        @batch_members,
        serializer: IdentityKooragang::KooragangMemberSyncPushSerializer,
        audience_id: 1,
        campaign_id: @kooragang_campaign.id,
        phone_type: 'mobile'
      ).as_json
    end

    it 'has inserted the correct callees to Kooragang' do
      IdentityKooragang::Callee.add_members(@rows)
      expect(@kooragang_campaign.callees.count).to eq(1)
      expect(@kooragang_campaign.callees.find_by_phone_number(@member.phone_numbers.mobile.first.phone).first_name).to eq(@member.first_name) # Kooragang allows external IDs to be text
    end

    it "doesn't insert duplicates into Kooragang" do
      2.times do |index|
        IdentityKooragang::Callee.add_members(@rows)
      end
      expect(@kooragang_campaign.callees.count).to eq(1)
      expect(@kooragang_campaign.callees.select('distinct phone_number').count).to eq(1)
    end
  end
end
