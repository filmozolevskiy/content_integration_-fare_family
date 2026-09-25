view: fare_family_events {
  sql_table_name: upsells.fare_family_upgrade_options_event ;;
  # Parallel event-table view for the new fare-family board (Trello #3121).
  # Independent of checkout_with_upsell / upsell_coverage_new; those stay until cut-over.
  # Visible surface is scoped to the checkout column set (context='checkout' board).

  # ------------------------------------------------------------------
  # Identifiers
  # ------------------------------------------------------------------

  dimension: event_id {
    primary_key: yes
    hidden: yes
    type: string
    sql: ${TABLE}.event_id ;;
    group_label: "01. Identifiers"
    label: "Event ID"
    # Why (2026-07-29, FM): source emits ~0.14%/day exact full-row duplicates and no
    # column combination dedups them, so this is an approximate key (~99.86% unique).
    # Safe as PK while the view has no joins; use distinct_event_count for entity counts.
    # Hidden from the picker per the checkout column set; still the primary key.
    description: "Event id. Approximate key — source emits ~0.14% duplicate rows; use Distinct Events for dedup-safe counts."
  }

  dimension: event_key {
    hidden: yes
    type: string
    sql: ${TABLE}.event_key ;;
    group_label: "01. Identifiers"
    label: "Event Key"
    description: "Grouping key for related events (search + package scope)."
  }

  dimension: search_id {
    hidden: yes
    type: string
    sql: ${TABLE}.search_id ;;
    group_label: "01. Identifiers"
    label: "Search ID"
    description: "Search this event belongs to."
  }

  dimension: base_package_id {
    hidden: yes
    type: string
    sql: ${TABLE}.base_package_id ;;
    group_label: "01. Identifiers"
    label: "Base Package ID"
    description: "Package the upgrade options were computed from."
  }

  dimension: current_package_id {
    hidden: yes
    type: string
    sql: ${TABLE}.current_package_id ;;
    group_label: "01. Identifiers"
    label: "Current Package ID"
    description: "Package currently selected (set once upgraded)."
  }

  dimension: checkout_id {
    hidden: yes
    type: string
    sql: ${TABLE}.checkout_id ;;
    group_label: "01. Identifiers"
    label: "Checkout ID"
    description: "Checkout id. Populated for context=checkout; NULL/undefined pre-checkout by design."
  }

  # ------------------------------------------------------------------
  # Timestamps
  # ------------------------------------------------------------------

  dimension_group: timestamp {
    type: time
    timeframes: [raw, time, hour, date, week, month, quarter, year]
    sql: ${TABLE}.timestamp ;;
    group_label: "02. Timestamps"
    label: "Event"
    description: "Event time (seconds). Primary time dimension."
  }

  dimension_group: timestamp_micro {
    hidden: yes
    type: time
    timeframes: [raw, time, hour, date, week, month]
    sql: ${TABLE}.timestamp_micro ;;
    group_label: "02. Timestamps"
    label: "Event (micro)"
    description: "Microsecond event time."
  }

  # ------------------------------------------------------------------
  # Context / attributes
  # ------------------------------------------------------------------

  dimension: context {
    hidden: yes
    type: string
    sql: ${TABLE}.context ;;
    group_label: "03. Context & Attributes"
    label: "Context"
    description: "Funnel stage: search_results_preload, search_results, checkout, unknown, post-booking."
    suggestions: ["search_results_preload", "search_results", "checkout", "unknown", "post-booking"]
  }

  dimension: device_type {
    type: string
    sql: ${TABLE}.device_type ;;
    group_label: "03. Context & Attributes"
    label: "Device Type"
    description: "desktop, mobile, mobile_app, tablet."
    suggestions: ["desktop", "mobile", "mobile_app", "tablet"]
  }

  dimension: site_id {
    hidden: yes
    type: number
    sql: ${TABLE}.site_id ;;
    group_label: "03. Context & Attributes"
    label: "Site ID"
    description: "Storefront. 1 and 4 are main; 5 = agencia."
  }

  dimension: affiliate_id {
    type: number
    sql: ${TABLE}.affiliate_id ;;
    group_label: "03. Context & Attributes"
    label: "Affiliate ID"
    description: "Affiliate."
  }

  dimension: currency {
    type: string
    sql: upper(${TABLE}.currency) ;;
    group_label: "03. Context & Attributes"
    label: "Currency"
    description: "Display currency, upper-cased (source sends both USD and usd)."
  }

  dimension: trip_type {
    type: string
    sql: ${TABLE}.trip_type ;;
    group_label: "03. Context & Attributes"
    label: "Trip Type"
    description: "oneway, roundtrip, etc."
  }

  dimension: is_multiticket {
    type: yesno
    sql: ${TABLE}.is_multiticket ;;
    group_label: "03. Context & Attributes"
    label: "Is Multiticket"
    description: "Multi-ticket combination (master + slave tickets)."
  }

  dimension: is_upgraded_package {
    type: yesno
    sql: ${TABLE}.is_upgraded_package ;;
    group_label: "03. Context & Attributes"
    label: "Is Upgraded Package"
    description: "Source flag: event is for an already-upgraded package. Not the canonical upgraded flag; use Is Upgraded Checkout for upgraded counts."
  }

  dimension: is_cached {
    hidden: yes
    type: yesno
    sql: ${TABLE}.is_cached ;;
    group_label: "03. Context & Attributes"
    label: "Is Cached"
    description: "Result served from cache (~98% of events)."
  }

  dimension: is_synthetic {
    type: yesno
    sql: ${TABLE}.is_synthetic ;;
    group_label: "03. Context & Attributes"
    label: "Is Synthetic"
    description: "Synthetic upgrade selection."
  }

  # ------------------------------------------------------------------
  # Eligibility
  # ------------------------------------------------------------------

  dimension: is_eligible {
    type: yesno
    sql: ${TABLE}.is_eligible ;;
    group_label: "04. Eligibility"
    label: "Is Eligible"
    description: "Source flag. Is eligible to call to Content source to get FF upgrade options?"
  }

  dimension: ineligibility_reason {
    type: string
    sql: ${TABLE}.ineligibility_reason ;;
    group_label: "04. Eligibility"
    label: "Ineligibility Reason"
    description: "Why the pacakge is ineligible to call Content source to get FF upgrade options?"
    suggestions: [
      "upsell_already_called_for_package",
      "upsell_already_called_for_upgraded_package",
      "ineligible_for_inl",
      "ineligible_for_bus_train",
      "ineligible_for_tablets",
      "ineligible_for_carrier",
      "ineligible_for_currency",
      "ineligible_for_base_package_mixed_fare_family"
    ]
  }

  dimension: no_options_reason {
    type: string
    sql: ${TABLE}.no_options_reason ;;
    group_label: "04. Eligibility"
    label: "No Options Reason"
    description: "Why we didn't display FF options?"
    suggestions: [
      "no_options_found",
      "all_options_filtered",
      "one_option_found"
    ]
  }

  dimension: gds_no_options_reason {
    type: string
    sql: ${TABLE}.gds_no_options_reason ;;
    group_label: "04. Eligibility"
    label: "GDS No Options Reason"
    description: "Why the GDS returned no options."
    suggestions: [
      "no_upsells_returned",
      "all_upsells_mixed_ff",
      "only_original_ff",
      "different_ptc",
      "original_package_highest_ff",
      "no_eligible_options",
      "upsell_not_returned_original_ff",
      "gds_timeout"
    ]
  }

  dimension: has_atpco_features {
    type: yesno
    sql: ${TABLE}.has_atpco_features ;;
    group_label: "04. Eligibility"
    label: "Has ATPCO Features"
    description: "ATPCO fare-family feature data present."
  }

  dimension: atpco_error {
    type: string
    sql: ${TABLE}.atpco_error ;;
    group_label: "04. Eligibility"
    label: "ATPCO Error"
    description: "ATPCO error, if any."
  }

  # ------------------------------------------------------------------
  # Upgrade source
  # ------------------------------------------------------------------

  dimension: master_upgrade_source {
    type: string
    sql: ${TABLE}.master_upgrade_source ;;
    group_label: "05. Upgrade Source"
    label: "Master Upgrade Source"
    description: "Upgrade source for the master ticket."
  }

  dimension: slave_upgrade_source {
    type: string
    sql: ${TABLE}.slave_upgrade_source ;;
    group_label: "05. Upgrade Source"
    label: "Slave Upgrade Source"
    description: "Upgrade source for the slave ticket (multi-ticket)."
  }

  # ------------------------------------------------------------------
  # Options counts
  # ------------------------------------------------------------------

  dimension: master_gds_upsell_count {
    hidden: yes
    type: number
    sql: ${TABLE}.master_gds_upsell_count ;;
    group_label: "06. Options"
    label: "Master GDS Upsell Count"
    description: "GDS upsell options for the master ticket."
  }

  dimension: slave_gds_upsell_count {
    hidden: yes
    type: number
    sql: ${TABLE}.slave_gds_upsell_count ;;
    group_label: "06. Options"
    label: "Slave GDS Upsell Count"
    description: "GDS upsell options for the slave ticket."
  }

  dimension: master_options_displayed_count {
    hidden: yes
    type: number
    sql: ${TABLE}.master_options_displayed_count ;;
    group_label: "06. Options"
    label: "Master Options Displayed"
    description: "Options actually displayed to the user (master)."
  }

  dimension: slave_options_displayed_count {
    hidden: yes
    type: number
    sql: ${TABLE}.slave_options_displayed_count ;;
    group_label: "06. Options"
    label: "Slave Options Displayed"
    description: "Options actually displayed to the user (slave)."
  }

  dimension: master_fare_family_names {
    hidden: yes
    type: string
    sql: ${TABLE}.master_fare_family_names ;;
    group_label: "06. Options"
    label: "Master Fare Family Names"
    description: "Fare-family names offered (master)."
  }

  dimension: slave_fare_family_names {
    hidden: yes
    type: string
    sql: ${TABLE}.slave_fare_family_names ;;
    group_label: "06. Options"
    label: "Slave Fare Family Names"
    description: "Fare-family names offered (slave)."
  }

  dimension: master_displayed_fare_family_names {
    hidden: yes
    type: string
    sql: ${TABLE}.master_displayed_fare_family_names ;;
    group_label: "06. Options"
    label: "Master Displayed Fare Family Names"
    description: "Fare-family names displayed (master)."
  }

  dimension: slave_displayed_fare_family_names {
    hidden: yes
    type: string
    sql: ${TABLE}.slave_displayed_fare_family_names ;;
    group_label: "06. Options"
    label: "Slave Displayed Fare Family Names"
    description: "Fare-family names displayed (slave)."
  }

  dimension: has_options_displayed {
    # Why (2026-09-25, FM): a displayed count of 1 is the original fare only.
    # Single-ticket events with count = 1 always carry no_options_reason and an
    # empty displayed fare-family list (3,419 events on 2026-09-22 NY); count >= 2
    # never does (0 events, 2026-09-18 to 09-24). "> 0" put those checkouts in
    # both Checkout Coverage and the no-options buckets (71.17% vs 67.18%).
    type: yesno
    sql: ${master_options_displayed_count} > 1 OR ${slave_options_displayed_count} > 1 ;;
    group_label: "06. Options"
    label: "Has Options Displayed"
    description: "Yes when the customer could choose an upgrade: more than 1 fare family displayed on master or slave. A count of 1 is the original fare only (no upgrade)."
  }

  dimension: has_gds_options {
    type: yesno
    sql: (${master_gds_upsell_count} + ${slave_gds_upsell_count}) > 0 ;;
    group_label: "06. Options"
    label: "Has GDS Options Returned"
    description: "Yes when the content source returned any upsell options (master + slave GDS upsell count > 0). Counts options RETURNED, not necessarily usable — mixed-fare-family and original-highest cases still count here."
  }

  dimension: is_repetitive_checkout {
    type: yesno
    sql: ${ineligibility_reason} = 'upsell_already_called_for_package' ;;
    group_label: "04. Eligibility"
    label: "Is Repetitive Checkout"
    description: "Yes when the upsell was already called for this package (ineligibility_reason = upsell_already_called_for_package) — a cached re-render."
  }

  dimension: is_upgraded_checkout {
    type: yesno
    sql: ${ineligibility_reason} = 'upsell_already_called_for_upgraded_package' ;;
    group_label: "04. Eligibility"
    label: "Is Upgraded Checkout"
    description: "Yes when the upsell was already called for an upgraded package (ineligibility_reason = upsell_already_called_for_upgraded_package)."
  }

  # ------------------------------------------------------------------
  # Filtered options (dropped before display)
  # ------------------------------------------------------------------

  dimension: master_filtered_empty_count {
    hidden: yes
    type: number
    sql: ${TABLE}.master_filtered_empty_count ;;
    group_label: "06a. Filtered Options"
    label: "Master Filtered Empty"
    description: "Options dropped as empty (master)."
  }

  dimension: slave_filtered_empty_count {
    hidden: yes
    type: number
    sql: ${TABLE}.slave_filtered_empty_count ;;
    group_label: "06a. Filtered Options"
    label: "Slave Filtered Empty"
    description: "Options dropped as empty (slave)."
  }

  dimension: master_filtered_cheaper_count {
    hidden: yes
    type: number
    sql: ${TABLE}.master_filtered_cheaper_count ;;
    group_label: "06a. Filtered Options"
    label: "Master Filtered Cheaper"
    description: "Options dropped as cheaper than base (master)."
  }

  dimension: slave_filtered_cheaper_count {
    hidden: yes
    type: number
    sql: ${TABLE}.slave_filtered_cheaper_count ;;
    group_label: "06a. Filtered Options"
    label: "Slave Filtered Cheaper"
    description: "Options dropped as cheaper than base (slave)."
  }

  dimension: master_filtered_lesser_count {
    hidden: yes
    type: number
    sql: ${TABLE}.master_filtered_lesser_count ;;
    group_label: "06a. Filtered Options"
    label: "Master Filtered Lesser"
    description: "Options dropped as lesser value (master)."
  }

  dimension: slave_filtered_lesser_count {
    hidden: yes
    type: number
    sql: ${TABLE}.slave_filtered_lesser_count ;;
    group_label: "06a. Filtered Options"
    label: "Slave Filtered Lesser"
    description: "Options dropped as lesser value (slave)."
  }

  dimension: master_filtered_multiticket_count {
    hidden: yes
    type: number
    sql: ${TABLE}.master_filtered_multiticket_count ;;
    group_label: "06a. Filtered Options"
    label: "Master Filtered Multiticket"
    description: "Options dropped by multi-ticket rules (master)."
  }

  dimension: slave_filtered_multiticket_count {
    hidden: yes
    type: number
    sql: ${TABLE}.slave_filtered_multiticket_count ;;
    group_label: "06a. Filtered Options"
    label: "Slave Filtered Multiticket"
    description: "Options dropped by multi-ticket rules (slave)."
  }

  dimension: master_filtered_price_cap_count {
    hidden: yes
    type: number
    sql: ${TABLE}.master_filtered_price_cap_count ;;
    group_label: "06a. Filtered Options"
    label: "Master Filtered Price Cap"
    description: "Options dropped by price cap (master)."
  }

  dimension: slave_filtered_price_cap_count {
    hidden: yes
    type: number
    sql: ${TABLE}.slave_filtered_price_cap_count ;;
    group_label: "06a. Filtered Options"
    label: "Slave Filtered Price Cap"
    description: "Options dropped by price cap (slave)."
  }

  # ------------------------------------------------------------------
  # Passengers (hidden — not part of the checkout column set)
  # ------------------------------------------------------------------

  dimension: adt_pax_count {
    hidden: yes
    type: number
    sql: ${TABLE}.adt_pax_count ;;
    group_label: "07. Passengers"
    label: "Adults"
    description: "Adult passenger count."
  }

  dimension: chd_pax_count {
    hidden: yes
    type: number
    sql: ${TABLE}.chd_pax_count ;;
    group_label: "07. Passengers"
    label: "Children"
    description: "Child passenger count."
  }

  dimension: ins_pax_count {
    hidden: yes
    type: number
    sql: ${TABLE}.ins_pax_count ;;
    group_label: "07. Passengers"
    label: "Infants (seat)"
    description: "Infant-with-seat passenger count."
  }

  dimension: inl_pax_count {
    hidden: yes
    type: number
    sql: ${TABLE}.inl_pax_count ;;
    group_label: "07. Passengers"
    label: "Infants (lap)"
    description: "Infant-on-lap passenger count."
  }

  dimension: total_pax_count {
    hidden: yes
    type: number
    sql: ${adt_pax_count} + ${chd_pax_count} + ${ins_pax_count} + ${inl_pax_count} ;;
    group_label: "07. Passengers"
    label: "Total Passengers"
    description: "Sum of adult, child, infant-seat and infant-lap counts."
  }

  # ------------------------------------------------------------------
  # Carriers / GDS routing
  # ------------------------------------------------------------------

  dimension: master_marketing_carriers {
    type: string
    sql: ${TABLE}.master_marketing_carriers ;;
    group_label: "08. Carriers"
    label: "Master Marketing Carriers"
    description: "Marketing carriers (master)."
  }

  dimension: slave_marketing_carriers {
    type: string
    sql: ${TABLE}.slave_marketing_carriers ;;
    group_label: "08. Carriers"
    label: "Slave Marketing Carriers"
    description: "Marketing carriers (slave)."
  }

  dimension: master_operating_carriers {
    type: string
    sql: ${TABLE}.master_operating_carriers ;;
    group_label: "08. Carriers"
    label: "Master Operating Carriers"
    description: "Operating carriers (master)."
  }

  dimension: slave_operating_carriers {
    type: string
    sql: ${TABLE}.slave_operating_carriers ;;
    group_label: "08. Carriers"
    label: "Slave Operating Carriers"
    description: "Operating carriers (slave)."
  }

  dimension: master_validating_carrier {
    type: string
    sql: ${TABLE}.master_validating_carrier ;;
    group_label: "08. Carriers"
    label: "Master Validating Carrier"
    description: "Validating carrier (master)."
  }

  dimension: slave_validating_carrier {
    type: string
    sql: ${TABLE}.slave_validating_carrier ;;
    group_label: "08. Carriers"
    label: "Slave Validating Carrier"
    description: "Validating carrier (slave)."
  }

  dimension: original_master_gds {
    type: string
    sql: ${TABLE}.original_master_gds ;;
    group_label: "09. GDS Routing"
    label: "Original Master GDS"
    description: "GDS of the base package (master)."
  }

  dimension: original_slave_gds {
    type: string
    sql: ${TABLE}.original_slave_gds ;;
    group_label: "09. GDS Routing"
    label: "Original Slave GDS"
    description: "GDS of the base package (slave)."
  }

  dimension: current_master_gds {
    type: string
    sql: ${TABLE}.current_master_gds ;;
    group_label: "09. GDS Routing"
    label: "Current Master GDS"
    description: "GDS of the current/upgraded package (master)."
  }

  dimension: current_slave_gds {
    type: string
    sql: ${TABLE}.current_slave_gds ;;
    group_label: "09. GDS Routing"
    label: "Current Slave GDS"
    description: "GDS of the current/upgraded package (slave)."
  }

  dimension: original_master_office_id {
    type: string
    sql: ${TABLE}.original_master_office_id ;;
    group_label: "09. GDS Routing"
    label: "Original Master Office ID"
    description: "Office id of the base package (master)."
  }

  dimension: original_slave_office_id {
    type: string
    sql: ${TABLE}.original_slave_office_id ;;
    group_label: "09. GDS Routing"
    label: "Original Slave Office ID"
    description: "Office id of the base package (slave)."
  }

  dimension: current_master_office_id {
    type: string
    sql: ${TABLE}.current_master_office_id ;;
    group_label: "09. GDS Routing"
    label: "Current Master Office ID"
    description: "Office id of the current/upgraded package (master)."
  }

  dimension: current_slave_office_id {
    type: string
    sql: ${TABLE}.current_slave_office_id ;;
    group_label: "09. GDS Routing"
    label: "Current Slave Office ID"
    description: "Office id of the current/upgraded package (slave)."
  }

  dimension: original_master_target_id {
    type: number
    sql: ${TABLE}.original_master_target_id ;;
    group_label: "09. GDS Routing"
    label: "Original Master Target ID"
    description: "Target id of the base package (master)."
  }

  dimension: original_slave_target_id {
    type: number
    sql: ${TABLE}.original_slave_target_id ;;
    group_label: "09. GDS Routing"
    label: "Original Slave Target ID"
    description: "Target id of the base package (slave)."
  }

  dimension: current_master_target_id {
    hidden: yes
    type: number
    sql: ${TABLE}.current_master_target_id ;;
    group_label: "09. GDS Routing"
    label: "Current Master Target ID"
    description: "Target id of the current/upgraded package (master)."
  }

  dimension: current_slave_target_id {
    hidden: yes
    type: number
    sql: ${TABLE}.current_slave_target_id ;;
    group_label: "09. GDS Routing"
    label: "Current Slave Target ID"
    description: "Target id of the current/upgraded package (slave)."
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
    description: "Air revenue before upgrade. Set on every checkout event. Median ~10 CAD / ~4 USD; can be negative (13% CAD, 28% USD events on 2026-09-22). Unit unconfirmed: likely our margin on the air part, not the fare."
  }

  dimension: current_air_revenue {
    type: number
    sql: ${TABLE}.current_air_revenue ;;
    group_label: "10. Revenue"
    label: "Current Air Revenue"
    value_format_name: decimal_2
    description: "Air revenue after upgrade. Set on every checkout event. Can be negative. Unit unconfirmed: likely our margin on the air part, not the fare."
  }

  # ------------------------------------------------------------------
  # Hidden helpers
  # ------------------------------------------------------------------

  dimension: has_valid_checkout_id {
    hidden: yes
    type: yesno
    sql: ${checkout_id} IS NOT NULL AND ${checkout_id} != '' AND ${checkout_id} != 'undefined' ;;
  }


  # ------------------------------------------------------------------
  # Measures
  # ------------------------------------------------------------------

  measure: event_rows_nbr {
    alias: [count]
    type: count
    group_label: "11. Measures"
    label: "Event Rows #"
    description: "Row count (includes ~0.14% source duplicates — use Distinct Events # for entities)."
    drill_fields: [event_id, search_id, base_package_id, context, device_type, timestamp_time]
  }

  measure: distinct_events_nbr {
    alias: [distinct_event_count]
    hidden: yes
    type: count_distinct
    sql: ${event_id} ;;
    group_label: "11. Measures"
    label: "Distinct Events #"
    description: "count_distinct(event_id). Dedup-safe count."
  }

  measure: checkout_packages_nbr {
    type: count_distinct
    sql: ${event_key} ;;
    filters: [has_valid_checkout_id: "yes"]
    group_label: "11. Measures"
    label: "Checkout Package #"
    description: "Distinct packages (event_key = one search + one package) that reached the checkout page. One package can have several checkouts. Denominator for Booking Rate %."
  }

  measure: booked_packages_nbr {
    type: count_distinct
    sql: ${event_key} ;;
    filters: [has_valid_checkout_id: "yes", fare_family_booking_lookup.is_booked: "yes"]
    group_label: "11. Measures"
    label: "Booked Package #"
    description: "Checkout packages linked to a booking through event_key. One booking = one package."
  }

  # Why (2026-09-25, FM): package grain, not checkout grain. One event_key holds
  # several checkouts, so a checkout-grain rate credited ~25% of bookings to 2+
  # checkouts (9,058 booked checkouts vs 6,552 bookings on 2026-09-22 NY).
  measure: booking_rate_pct {
    type: number
    sql: 1.0 * ${booked_packages_nbr} / NULLIF(${checkout_packages_nbr}, 0) ;;
    value_format_name: percent_2
    group_label: "11. Measures"
    label: "Booking Rate %"
    description: "Booked packages / checkout packages. Counts completed customer bookings only (~99% of MySQL booked bookings, sites 1 and 4, master leg only); failed bookings without a PNR mostly have no post-booking event."
  }

  # ------------------------------------------------------------------
  # Checkout-grain coverage funnel (Trello #3121). Grain = distinct checkout_id
  # in checkout context; every numerator is count_distinct(checkout_id), so
  # cached re-render events do not inflate rates. Denominator = distinct_checkouts_nbr.
  # A checkout counts in a bucket when any of its events meets the condition,
  # so buckets overlap and do not add up to 100%. New-table metric; NOT
  # comparable to board 1518 coverage.
  # ------------------------------------------------------------------

  measure: distinct_checkouts_nbr {
    alias: [distinct_checkouts]
    type: count_distinct
    sql: ${checkout_id} ;;
    filters: [has_valid_checkout_id: "yes"]
    group_label: "12. Coverage Funnel"
    label: "Checkout #"
    description: "count_distinct(checkout_id) in checkout context. Denominator for checkout coverage."
  }

  measure: checkouts_with_options_nbr {
    alias: [checkouts_with_options]
    type: count_distinct
    sql: ${checkout_id} ;;
    filters: [has_valid_checkout_id: "yes", has_options_displayed: "yes"]
    group_label: "12. Coverage Funnel"
    label: "Checkouts with Options Available #"
    description: "Distinct checkouts with at least one event where an upgrade was displayed (more than the original fare, on master or slave)."
  }

  measure: checkout_coverage_pct {
    type: number
    sql: 1.0 * ${checkouts_with_options_nbr} / NULLIF(${distinct_checkouts_nbr}, 0) ;;
    value_format_name: percent_1
    group_label: "12. Coverage Funnel"
    label: "Checkout Coverage %"
    description: "Distinct checkouts with an upsell option available / distinct checkouts (checkout context). New-table metric; not comparable to board 1518 coverage."
  }

  measure: gds_options_returned_nbr {
    alias: [gds_options_returned_count]
    type: count_distinct
    sql: ${checkout_id} ;;
    filters: [has_valid_checkout_id: "yes", has_gds_options: "yes"]
    group_label: "12. Coverage Funnel"
    label: "Checkouts with Options Returned #"
    description: "Distinct checkouts where the content source returned upsell options (before display filtering)."
  }

  measure: gds_options_returned_pct {
    type: number
    sql: 1.0 * ${gds_options_returned_nbr} / NULLIF(${distinct_checkouts_nbr}, 0) ;;
    value_format_name: percent_2
    group_label: "12. Coverage Funnel"
    label: "Options Returned %"
    description: "Checkouts where the content source returned upsell options / distinct checkouts. Counts returned options, not necessarily usable ones."
  }

  measure: no_options_found_nbr {
    alias: [no_options_found_count]
    type: count_distinct
    sql: ${checkout_id} ;;
    filters: [has_valid_checkout_id: "yes", no_options_reason: "no_options_found"]
    group_label: "12. Coverage Funnel"
    label: "No Options Found #"
    description: "Checkouts where no upsell options were found. One checkout can be in several buckets; do not add them up."
  }

  measure: no_options_found_pct {
    type: number
    sql: 1.0 * ${no_options_found_nbr} / NULLIF(${distinct_checkouts_nbr}, 0) ;;
    value_format_name: percent_2
    group_label: "12. Coverage Funnel"
    label: "No Options Found %"
    description: "No-options-found checkouts / distinct checkouts. One checkout can be in several buckets; do not add them up."
  }

  measure: all_options_filtered_nbr {
    alias: [all_options_filtered_count]
    type: count_distinct
    sql: ${checkout_id} ;;
    filters: [has_valid_checkout_id: "yes", no_options_reason: "all_options_filtered"]
    group_label: "12. Coverage Funnel"
    label: "All Options Filtered #"
    description: "Checkouts where all options were filtered out before display. One checkout can be in several buckets; do not add them up."
  }

  measure: all_options_filtered_pct {
    type: number
    sql: 1.0 * ${all_options_filtered_nbr} / NULLIF(${distinct_checkouts_nbr}, 0) ;;
    value_format_name: percent_2
    group_label: "12. Coverage Funnel"
    label: "All Options Filtered %"
    description: "All-options-filtered checkouts / distinct checkouts. One checkout can be in several buckets; do not add them up."
  }

  measure: multiticket_checkouts_nbr {
    alias: [multiticket_checkouts]
    type: count_distinct
    sql: ${checkout_id} ;;
    filters: [has_valid_checkout_id: "yes", is_multiticket: "yes"]
    group_label: "12. Coverage Funnel"
    label: "Multiticket Checkouts #"
    description: "Distinct checkouts on multi-ticket combinations."
  }

  measure: non_multiticket_checkouts_nbr {
    alias: [non_multiticket_checkouts]
    type: count_distinct
    sql: ${checkout_id} ;;
    filters: [has_valid_checkout_id: "yes", is_multiticket: "no"]
    group_label: "12. Coverage Funnel"
    label: "Non-Multiticket Checkouts #"
    description: "Distinct checkouts on single-ticket combinations."
  }

  measure: multiticket_upgraded_checkouts_nbr {
    alias: [multiticket_upgraded_checkouts]
    type: count_distinct
    sql: ${checkout_id} ;;
    filters: [has_valid_checkout_id: "yes", is_multiticket: "yes", is_upgraded_checkout: "yes"]
    group_label: "12. Coverage Funnel"
    label: "Upgraded Multiticket Checkouts #"
    description: "Distinct upgraded checkouts on multi-ticket combinations."
  }

  measure: non_multiticket_upgraded_checkouts_nbr {
    alias: [non_multiticket_upgraded_checkouts]
    type: count_distinct
    sql: ${checkout_id} ;;
    filters: [has_valid_checkout_id: "yes", is_multiticket: "no", is_upgraded_checkout: "yes"]
    group_label: "12. Coverage Funnel"
    label: "Upgraded Non-Multiticket Checkouts #"
    description: "Distinct upgraded checkouts on single-ticket combinations."
  }
}
