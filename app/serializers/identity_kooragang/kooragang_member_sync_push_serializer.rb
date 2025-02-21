module IdentityKooragang
  class KooragangMemberSyncPushSerializer < ActiveModel::Serializer
    attributes :external_id, :first_name, :phone_number, :campaign_id, :audience_id, :data, :callable

    def external_id
      @object.id.to_s
    end

    def first_name
      @object.first_name ? @object.first_name : ''
    end

    def phone_number
      if instance_options[:phone_type] == 'all'
        number = @object.phone_numbers.first
      else
        number = @object.phone_numbers.send(instance_options[:phone_type]).first
      end
      number.phone if number
    end

    def campaign_id
      instance_options[:campaign_id]
    end

    def audience_id
      instance_options[:audience_id]
    end

    def data
      data = @object.flattened_custom_fields
      data['address'] = @object.address
      data['postcode'] = @object.postcode
      if instance_options[:include_rsvped_events]
        data['nationbuilder_id'] = @object.member_external_ids
                                          .where(system: 'nation_builder')
                                          .first()
                                          .try(:external_id)
        rsvps = EventRsvp.where(member_id: @object.id)
                         .joins(:event)
                         .where('events.start_time > now()')
                         .where("events.data->>'status' = 'published'")
        data["upcoming_rsvps"] = rsvps.each_with_index.map { |rsvp, index|
          "#{index + 1}. #{summarise_event(rsvp.event)}"
        }.join("\n")
      end
      data["areas"] = @object.areas.each_with_index.map { |area, _index|
        {
          name: area.name,
          code: area.code,
          area_type: area.area_type,
          party: area.party,
          representative_name: area.representative_name
        }
      }
      data.to_json
    end

    def callable
      true
    end

    private

    def summarise_event(event)
      start_time = Time.zone.parse(event.data['start_time']) rescue event.start_time
      summary = "#{event.name} at #{event.location} at #{start_time.strftime('%H:%M on %F')}"
      if (path = event.data['path'])
        summary += " (https://action.getup.org.au#{path})"
      end
      summary
    end
  end
end
