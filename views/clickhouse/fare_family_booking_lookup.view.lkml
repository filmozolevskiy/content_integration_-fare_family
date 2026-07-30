view: fare_family_booking_lookup {
  # Post-booking booking lookup, one row per event_key (Trello #3121).
  # booking_id only lands on context='post-booking' events; the checkout board is
  # checkout-grained, so this pre-aggregates the booking per event_key and is
  # left-joined onto fare_family_events by event_key. Looker prunes the join on
  # tiles that select no booking field, so non-booking tiles pay nothing.
  derived_table: {
    sql: SELECT event_key, max(booking_id) AS booking_id
         FROM upsells.fare_family_upgrade_options_event
         WHERE context = 'post-booking'
         GROUP BY event_key ;;
    datagroup_trigger: fare_family_events_daily
  }

  dimension: event_key {
    hidden: yes
    primary_key: yes
    type: string
    sql: ${TABLE}.event_key ;;
    # Join key back to fare_family_events. ~94% of bookings match a checkout event
    # in-window; ~0.9% of event_keys carry >1 booking and collapse via max().
  }

  dimension: booking_id {
    type: number
    sql: ${TABLE}.booking_id ;;
    group_label: "12. Bookings"
    label: "Booking ID"
    description: "Booking (ota.bookings.id) linked to the checkout event by event_key, from the post-booking event. ~5% of bookings have no in-window checkout event and will not appear."
  }

  dimension: is_booked {
    type: yesno
    sql: ${booking_id} IS NOT NULL ;;
    group_label: "12. Bookings"
    label: "Is Booked"
    description: "Checkout event matched to a booking via event_key."
  }

  measure: distinct_bookings {
    type: count_distinct
    sql: ${booking_id} ;;
    group_label: "12. Bookings"
    label: "Distinct Bookings"
    description: "count_distinct(booking_id) linked to checkout events in range."
  }
}
