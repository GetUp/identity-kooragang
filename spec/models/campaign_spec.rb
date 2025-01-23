describe IdentityKooragang::Campaign do
  context '#syncable' do
    before(:each) do
      2.times do
        FactoryBot.create(:kooragang_campaign, status: 'active')
      end
      FactoryBot.create(:kooragang_campaign, status: 'active', sync_to_identity: false)
      FactoryBot.create(:kooragang_campaign, status: 'paused')
      FactoryBot.create(:kooragang_campaign, status: 'inactive')
    end

    it 'returns syncable campaigns' do
      IdentityKooragang::Campaign.syncable.each do |campaign|
        expect(campaign).not_to have_attributes(status: 'inactive')
      end
      expect(IdentityKooragang::Campaign.syncable.count).to eq(3)
    end
  end
end
