view: fare_family_events {
  sql_table_name: upsells.fare_family_upgrade_options_event ;;
  # Parallel event-table view for the new fare-family board (Trello #3121).
  # Independent of checkout_with_upsell / upsell_coverage_new; those stay until cut-over.

  # ------------------------------------------------------------------
  # Identifiers
  # ------------------------------------------------------------------

  dimension: event_id {
    primary_key: yes
    type: string
    sql: ${TABLE}.event_id ;;
    group_label: "1. Identifiers"
    label: "Event ID"
    # Why (2026-07-29, FM): source emits ~0.14%/day exact full-row duplicates and no
    # column combination dedups them, so this is an approximate key (~99.86% unique).
    # Safe as PK while the view has no joins; use distinct_event_count for entity counts.
    description: "Event id. Approximate key — source emits ~0.14% duplicate rows; use Distinct Events for dedup-safe counts."
  }

  dimension: event_key {
    type: string
    sql: ${TABLE}.event_key ;;
    group_label: "1. Identifiers"
    label: "Event Key"
    description: "Grouping key for related events (search + package scope)."
  }

  dimension: search_id {
    type: string
    sql: ${TABLE}.search_id ;;
    group_label: "1. Identifiers"
    label: "Search ID"
    description: "Search this event belongs to."
  }

  dimension: base_package_id {
    type: string
    sql: ${TABLE}.base_package_id ;;
    group_label: "1. Identifiers"
    label: "Base Package ID"
    description: "Package the upgrade options were computed from."
  }

  dimension: current_package_id {
    type: string
    sql: ${TABLE}.current_package_id ;;
    group_label: "1. Identifiers"
    label: "Current Package ID"
    description: "Package currently selected (set once upgraded)."
  }

  dimension: checkout_id {
    type: string
    sql: ${TABLE}.checkout_id ;;
    group_label: "1. Identifiers"
    label: "Checkout ID"
    description: "Checkout id. Populated for context=checkout; NULL/undefined pre-checkout by design."
  }

  dimension: booking_id {
    type: number
    sql: ${TABLE}.booking_id ;;
    group_label: "1. Identifiers"
    label: "Booking ID"
    description: "Resulting ota.bookings.id. Sparsely populated (~0.05%) until linkage lands."
  }

  # ------------------------------------------------------------------
  # Timestamps
  # ------------------------------------------------------------------

  dimension_group: timestamp {
    type: time
    timeframes: [raw, time, hour, date, week, month, quarter, year]
    sql: ${TABLE}.timestamp ;;
    group_label: "2. Timestamps"
    label: "Event"
    description: "Event time (seconds)."
  }

  dimension_group: timestamp_micro {
    type: time
    timeframes: [raw, time, hour, date, week, month]
    sql: ${TABLE}.timestamp_micro ;;
    group_label: "2. Timestamps"
    label: "Event (micro)"
    description: "Microsecond event time."
  }

  # ------------------------------------------------------------------
  # Context / attributes
  # ------------------------------------------------------------------

  dimension: context {
    type: string
    sql: ${TABLE}.context ;;
    group_label: "3. Context & Attributes"
    label: "Context"
    description: "Funnel stage: search_results_preload, search_results, checkout, unknown, post-booking."
    suggestions: ["search_results_preload", "search_results", "checkout", "unknown", "post-booking"]
  }

  dimension: device_type {
    type: string
    sql: ${TABLE}.device_type ;;
    group_label: "3. Context & Attributes"
    label: "Device Type"
    description: "desktop, mobile, mobile_app, tablet."
    suggestions: ["desktop", "mobile", "mobile_app", "tablet"]
  }

  dimension: site_id {
    type: number
    sql: ${TABLE}.site_id ;;
    group_label: "3. Context & Attributes"
    label: "Site ID"
    description: "Storefront. 1 and 4 are main; 5 = agencia."
  }

  dimension: affiliate_id {
    type: number
    sql: ${TABLE}.affiliate_id ;;
    group_label: "3. Context & Attributes"
    label: "Affiliate ID"
    description: "Affiliate."
  }

  dimension: currency {
    type: string
    sql: ${TABLE}.currency ;;
    group_label: "3. Context & Attributes"
    label: "Currency"
    description: "Display currency."
  }

  dimension: trip_type {
    type: string
    sql: ${TABLE}.trip_type ;;
    group_label: "3. Context & Attributes"
    label: "Trip Type"
    description: "oneway, roundtrip, etc."
  }

  dimension: is_multiticket {
    type: yesno
    sql: ${TABLE}.is_multiticket ;;
    group_label: "3. Context & Attributes"
    label: "Is Multiticket"
    description: "Multi-ticket combination (master + slave tickets)."
  }

  dimension: is_upgraded_package {
    type: yesno
    sql: ${TABLE}.is_upgraded_package ;;
    group_label: "3. Context & Attributes"
    label: "Is Upgraded Package"
    description: "Event is for an already-upgraded package."
  }

  dimension: is_cached {
    type: yesno
    sql: ${TABLE}.is_cached ;;
    group_label: "3. Context & Attributes"
    label: "Is Cached"
    description: "Result served from cache (~98% of events)."
  }

  dimension: is_synthetic {
    type: yesno
    sql: ${TABLE}.is_synthetic ;;
    group_label: "3. Context & Attributes"
    label: "Is Synthetic"
    description: "Synthetic upgrade selection."
  }

  # ------------------------------------------------------------------
  # Eligibility
  # ------------------------------------------------------------------

  dimension: is_eligible {
    type: yesno
    sql: ${TABLE}.is_eligible ;;
    group_label: "4. Eligibility"
    label: "Is Eligible"
    # Why (2026-07-29, FM): near-always False (True on ~2 rows/3d) and not an
    # "upsell shown" flag; do not use as a rate denominator until source confirms meaning.
    description: "Source flag, near-always False. NOT an upsell-shown flag — confirm meaning before using in rates."
  }

  dimension: ineligibility_reason {
    type: string
    sql: ${TABLE}.ineligibility_reason ;;
    group_label: "4. Eligibility"
    label: "Ineligibility Reason"
    description: "Why ineligible; dominated by upsell_already_called_for_package (preload dedup)."
  }

  dimension: no_options_reason {
    type: string
    sql: ${TABLE}.no_options_reason ;;
    group_label: "4. Eligibility"
    label: "No Options Reason"
    description: "None (options shown), no_options_found, all_options_filtered, one_option_found."
  }

  dimension: gds_no_options_reason {
    type: string
    sql: ${TABLE}.gds_no_options_reason ;;
    group_label: "4. Eligibility"
    label: "GDS No Options Reason"
    description: "Why the GDS returned no options."
  }

  dimension: has_atpco_features {
    type: yesno
    sql: ${TABLE}.has_atpco_features ;;
    group_label: "4. Eligibility"
    label: "Has ATPCO Features"
    description: "ATPCO fare-family feature data present."
  }

  dimension: atpco_error {
    type: string
    sql: ${TABLE}.atpco_error ;;
    group_label: "4. Eligibility"
    label: "ATPCO Error"
    description: "ATPCO error, if any."
  }

  # ------------------------------------------------------------------
  # Upgrade source
  # ------------------------------------------------------------------

  dimension: master_upgrade_source {
    type: string
    sql: ${TABLE}.master_upgrade_source ;;
    group_label: "5. Upgrade Source"
    label: "Master Upgrade Source"
    description: "Upgrade source for the master ticket."
  }

  dimension: slave_upgrade_source {
    type: string
    sql: ${TABLE}.slave_upgrade_source ;;
    group_label: "5. Upgrade Source"
    label: "Slave Upgrade Source"
    description: "Upgrade source for the slave ticket (multi-ticket)."
  }

  # ------------------------------------------------------------------
  # Options counts
  # ------------------------------------------------------------------

  dimension: master_gds_upsell_count {
    type: number
    sql: ${TABLE}.master_gds_upsell_count ;;
    group_label: "6. Options"
    label: "Master GDS Upsell Count"
    description: "GDS upsell options for the master ticket."
  }

  dimension: slave_gds_upsell_count {
    type: number
    sql: ${TABLE}.slave_gds_upsell_count ;;
    group_label: "6. Options"
    label: "Slave GDS Upsell Count"
    description: "GDS upsell options for the slave ticket."
  }

  dimension: master_options_displayed_count {
    type: number
    sql: ${TABLE}.master_options_displayed_count ;;
    group_label: "6. Options"
    label: "Master Options Displayed"
    description: "Options actually displayed to the user (master)."
  }

  dimension: slave_options_displayed_count {
    type: number
    sql: ${TABLE}.slave_options_displayed_count ;;
    group_label: "6. Options"
    label: "Slave Options Displayed"
    description: "Options actually displayed to the user (slave)."
  }

  dimension: master_fare_family_names {
    type: string
    sql: ${TABLE}.master_fare_family_names ;;
    group_label: "6. Options"
    label: "Master Fare Family Names"
    description: "Fare-family names offered (master)."
  }

  dimension: slave_fare_family_names {
    type: string
    sql: ${TABLE}.slave_fare_family_names ;;
    group_label: "6. Options"
    label: "Slave Fare Family Names"
    description: "Fare-family names offered (slave)."
  }

  dimension: master_displayed_fare_family_names {
    type: string
    sql: ${TABLE}.master_displayed_fare_family_names ;;
    group_label: "6. Options"
    label: "Master Displayed Fare Family Names"
    description: "Fare-family names displayed (master)."
  }

  dimension: slave_displayed_fare_family_names {
    type: string
    sql: ${TABLE}.slave_displayed_fare_family_names ;;
    group_label: "6. Options"
    label: "Slave Displayed Fare Family Names"
    description: "Fare-family names displayed (slave)."
  }

  # ------------------------------------------------------------------
  # Passengers
  # ------------------------------------------------------------------

  dimension: adt_pax_count {
    type: number
    sql: ${TABLE}.adt_pax_count ;;
    group_label: "7. Passengers"
    label: "Adults"
    description: "Adult passenger count."
  }

  dimension: chd_pax_count {
    type: number
    sql: ${TABLE}.chd_pax_count ;;
    group_label: "7. Passengers"
    label: "Children"
    description: "Child passenger count."
  }

  dimension: ins_pax_count {
    type: number
    sql: ${TABLE}.ins_pax_count ;;
    group_label: "7. Passengers"
    label: "Infants (seat)"
    description: "Infant-with-seat passenger count."
  }

  dimension: inl_pax_count {
    type: number
    sql: ${TABLE}.inl_pax_count ;;
    group_label: "7. Passengers"
    label: "Infants (lap)"
    description: "Infant-on-lap passenger count."
  }

  dimension: total_pax_count {
    type: number
    sql: ${adt_pax_count} + ${chd_pax_count} + ${ins_pax_count} + ${inl_pax_count} ;;
    group_label: "7. Passengers"
    label: "Total Passengers"
    description: "Sum of adult, child, infant-seat and infant-lap counts."
  }

  # ------------------------------------------------------------------
  # Carriers / GDS routing
  # ------------------------------------------------------------------

  dimension: master_marketing_carriers {
    type: string
    sql: ${TABLE}.master_marketing_carriers ;;
    group_label: "8. Carriers"
    label: "Master Marketing Carriers"
    description: "Marketing carriers (master)."
  }

  dimension: slave_marketing_carriers {
    type: string
    sql: ${TABLE}.slave_marketing_carriers ;;
    group_label: "8. Carriers"
    label: "Slave Marketing Carriers"
    description: "Marketing carriers (slave)."
  }

  dimension: master_operating_carriers {
    type: string
    sql: ${TABLE}.master_operating_carriers ;;
    group_label: "8. Carriers"
    label: "Master Operating Carriers"
    description: "Operating carriers (master)."
  }

  dimension: slave_operating_carriers {
    type: string
    sql: ${TABLE}.slave_operating_carriers ;;
    group_label: "8. Carriers"
    label: "Slave Operating Carriers"
    description: "Operating carriers (slave)."
  }

  dimension: master_validating_carrier {
    type: string
    sql: ${TABLE}.master_validating_carrier ;;
    group_label: "8. Carriers"
    label: "Master Validating Carrier"
    description: "Validating carrier (master)."
  }

  dimension: slave_validating_carrier {
    type: string
    sql: ${TABLE}.slave_validating_carrier ;;
    group_label: "8. Carriers"
    label: "Slave Validating Carrier"
    description: "Validating carrier (slave)."
  }

  dimension: original_master_gds {
    type: string
    sql: ${TABLE}.original_master_gds ;;
    group_label: "9. GDS Routing"
    label: "Original Master GDS"
    description: "GDS of the base package (master)."
  }

  dimension: original_slave_gds {
    type: string
    sql: ${TABLE}.original_slave_gds ;;
    group_label: "9. GDS Routing"
    label: "Original Slave GDS"
    description: "GDS of the base package (slave)."
  }

  dimension: current_master_gds {
    type: string
    sql: ${TABLE}.current_master_gds ;;
    group_label: "9. GDS Routing"
    label: "Current Master GDS"
    description: "GDS of the current/upgraded package (master)."
  }

  dimension: current_slave_gds {
    type: string
    sql: ${TABLE}.current_slave_gds ;;
    group_label: "9. GDS Routing"
    label: "Current Slave GDS"
    description: "GDS of the current/upgraded package (slave)."
  }

  dimension: original_master_office_id {
    type: string
    sql: ${TABLE}.original_master_office_id ;;
    group_label: "9. GDS Routing"
    label: "Original Master Office ID"
    description: "Office id of the base package (master)."
  }

  dimension: current_master_office_id {
    type: string
    sql: ${TABLE}.current_master_office_id ;;
    group_label: "9. GDS Routing"
    label: "Current Master Office ID"
    description: "Office id of the current/upgraded package (master)."
  }

  # ------------------------------------------------------------------
  # Revenue
  # ------------------------------------------------------------------

  dimension: original_air_revenue {
    type: number
    sql: ${TABLE}.original_air_revenue ;;
    group_label: "10. Revenue"
    label: "Original Air Revenue"
    value_format_name: decimal_2
    description: "Air revenue before upgrade. ~13% populated; confirm unit with source."
  }

  dimension: current_air_revenue {
    type: number
    sql: ${TABLE}.current_air_revenue ;;
    group_label: "10. Revenue"
    label: "Current Air Revenue"
    value_format_name: decimal_2
    description: "Air revenue after upgrade. Populated with original_air_revenue."
  }

  # ------------------------------------------------------------------
  # Hidden helpers
  # ------------------------------------------------------------------

  dimension: has_valid_checkout_id {
    hidden: yes
    type: yesno
    sql: ${checkout_id} IS NOT NULL AND ${checkout_id} != '' AND ${checkout_id} != 'undefined' ;;
  }

  dimension: has_booking_id {
    hidden: yes
    type: yesno
    sql: ${booking_id} IS NOT NULL ;;
  }

  dimension: has_options_displayed {
    hidden: yes
    type: yesno
    sql: ${master_options_displayed_count} > 0 OR ${slave_options_displayed_count} > 0 ;;
  }

  # ------------------------------------------------------------------
  # Measures
  # ------------------------------------------------------------------

  measure: count {
    type: count
    group_label: "11. Measures"
    label: "Event Rows"
    description: "Row count (includes ~0.14% source duplicates — use Distinct Events for entities)."
    drill_fields: [event_id, search_id, base_package_id, context, device_type, timestamp_time]
  }

  measure: distinct_event_count {
    type: count_distinct
    sql: ${event_id} ;;
    group_label: "11. Measures"
    label: "Distinct Events"
    description: "count_distinct(event_id). Dedup-safe count."
  }

  measure: checkout_context_count {
    type: count
    filters: [context: "checkout"]
    group_label: "11. Measures"
    label: "Checkout-context Events"
    description: "Events at context=checkout. Denominator for checkout_id coverage."
  }

  measure: checkout_id_coverage_count {
    type: count
    filters: [context: "checkout", has_valid_checkout_id: "yes"]
    group_label: "11. Measures"
    label: "Checkout Events with checkout_id"
    description: "Checkout-context events carrying a usable checkout_id."
  }

  measure: checkout_id_coverage_pct {
    type: number
    sql: 1.0 * ${checkout_id_coverage_count} / NULLIF(${checkout_context_count}, 0) ;;
    value_format_name: percent_2
    group_label: "11. Measures"
    label: "checkout_id Coverage (checkout)"
    description: "Share of checkout-context events with a usable checkout_id. QA gap tracker for mobile app / agencia."
  }

  measure: booking_linked_count {
    type: count
    filters: [has_booking_id: "yes"]
    group_label: "11. Measures"
    label: "Events Linked to a Booking"
    description: "Events with booking_id populated. Near zero until linkage lands."
  }

  measure: options_displayed_event_count {
    type: count
    filters: [has_options_displayed: "yes"]
    group_label: "11. Measures"
    label: "Events with Options Displayed"
    description: "Events where master or slave options were displayed."
  }

  measure: total_current_air_revenue {
    type: sum
    sql: ${current_air_revenue} ;;
    value_format_name: decimal_2
    group_label: "11. Measures"
    label: "Total Current Air Revenue"
    description: "Sum of current_air_revenue (nulls excluded)."
  }

  measure: total_original_air_revenue {
    type: sum
    sql: ${original_air_revenue} ;;
    value_format_name: decimal_2
    group_label: "11. Measures"
    label: "Total Original Air Revenue"
    description: "Sum of original_air_revenue (nulls excluded)."
  }

  measure: total_air_revenue_uplift {
    type: sum
    sql: ${current_air_revenue} - ${original_air_revenue} ;;
    value_format_name: decimal_2
    group_label: "11. Measures"
    label: "Total Air Revenue Uplift"
    description: "Sum of (current - original) air revenue where both present."
  }
}
