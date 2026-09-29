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
datagroup: fare_family_checkouts_daily {
  sql_trigger: SELECT toDate(now()) ;;
  max_cache_age: "24 hours"
}

explore: fare_family_checkouts {
  label: "Fare Family Checkouts"
  description: "One row per checkout (checkout context). Upsell status, coverage, bookings and booked revenue."
  persist_with: fare_family_checkouts_daily
  # The date filter is pushed into the derived table; default 30 days.
  conditionally_filter: {
    filters: [fare_family_checkouts.checkout_date: "30 days"]
    unless:  [fare_family_checkouts.checkout_date]
  }
  # One row per ticket (leg). Used for coverage by carrier / content source.
  # With a leg field in the query, multi-ticket checkouts appear twice: counts
  # stay distinct on checkout_id; the booked revenue sums are not available.
  join: fare_family_checkout_legs {
    view_label: "Checkout Legs"
    relationship: one_to_many
    sql: ARRAY JOIN arrayFilter(l -> l.1 = 'Master' OR ${fare_family_checkouts.is_multiticket},
           [tuple('Master', ${fare_family_checkouts.master_validating_carrier}, ${fare_family_checkouts.original_master_gds},
                  ${fare_family_checkouts.original_master_office_id}, ${fare_family_checkouts.master_upgrade_source_gds},
                  ${fare_family_checkouts.master_has_options_displayed}, ${fare_family_checkouts.master_has_gds_options}),
            tuple('Slave', ${fare_family_checkouts.slave_validating_carrier}, ${fare_family_checkouts.original_slave_gds},
                  ${fare_family_checkouts.original_slave_office_id}, ${fare_family_checkouts.slave_upgrade_source_gds},
                  ${fare_family_checkouts.slave_has_options_displayed}, ${fare_family_checkouts.slave_has_gds_options})])
           AS fare_family_checkout_legs ;;
  }
}
