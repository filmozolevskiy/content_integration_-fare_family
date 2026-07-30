connection: "clickhouse-prod"

# Only include views that use ClickHouse
include: "/views/clickhouse/*.view.lkml"
include: "/views/clickhouse/upsell_coverage_new.view.lkml"

datagroup: checkout_with_upsell_daily {
  sql_trigger: SELECT toDate(now()) ;;
  max_cache_age: "24 hours"
}

# Define explores based on ClickHouse views
explore: checkout_with_upsell {
  label: "Checkout with Upsell"
  persist_with: checkout_with_upsell_daily
  conditionally_filter: {
    filters: [checkout_with_upsell.checkout_begin_checkout_timestamp_date: "60 days"]
    unless:  [checkout_with_upsell.checkout_begin_checkout_timestamp_date]
  }
}

explore: upsell_coverage_new {
  label: "Upsell Coverage New"
  }

# --- New parallel setup for the new fare-family board (Trello #3121) ---
# Independent of the two explores above; those stay until cut-over.
datagroup: fare_family_events_daily {
  sql_trigger: SELECT toDate(now()) ;;
  max_cache_age: "24 hours"
}

explore: fare_family_events {
  label: "Fare Family Events"
  persist_with: fare_family_events_daily
  # Lock the whole explore to the checkout funnel stage — applies to every
  # dimension and measure, non-overridable.
  sql_always_where: ${fare_family_events.context} = 'checkout' ;;
  conditionally_filter: {
    filters: [fare_family_events.timestamp_date: "30 days"]
    unless:  [fare_family_events.timestamp_date]
  }
  # Booking linkage: booking_id lives on post-booking events, so left-join the
  # per-event_key booking lookup. Pruned on tiles that select no booking field.
  join: fare_family_booking_lookup {
    type: left_outer
    relationship: many_to_one
    sql_on: ${fare_family_events.event_key} = ${fare_family_booking_lookup.event_key} ;;
  }
}
