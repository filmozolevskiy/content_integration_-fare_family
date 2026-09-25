view: fare_family_checkouts {
  # One row per checkout_id in checkout context (Trello #3121). Base of the
  # fare_family_checkouts explore; every measure is a plain count / sum.
  # Why (2026-09-25, FM):
  # - 95% of checkouts have 1 event; inside the rest, only revenue, the upgraded
  #   flag and a few reasons change (upgrade during checkout), so those come from
  #   the last event and the rest from any event (0 checkouts change value).
  # - Checkout Upsell Status = priority Upgraded > Fresh > Ineligible > Repetitive;
  #   customers upgrade after their first event, so a first-event rule misses upgrades.
  # - booking_id is credited to the last checkout of the booked package (event_key),
  #   so each booking belongs to exactly one checkout (6,552 = 6,552 on 2026-09-22 NY).
  # - Ephemeral SQL derived table — no datagroup_trigger (clickhouse-prod rejects PDTs).
  #   The explore's date filter is pushed into the checkouts CTE.
  derived_table: {
    sql: WITH checkouts AS (
           SELECT
             checkout_id,
             any(event_key) AS event_key,
             any(search_id) AS search_id,
             min(timestamp) AS checkout_at,
             max(timestamp_micro) AS last_event_at,
             uniqExact(event_id) AS event_count,
             multiIf(countIf(ineligibility_reason = 'upsell_already_called_for_upgraded_package') > 0, 'Upgraded',
                     countIf(ineligibility_reason IS NULL) > 0, 'Fresh',
                     countIf(ineligibility_reason LIKE 'ineligible_for_%') > 0, 'Ineligible',
                     countIf(ineligibility_reason = 'upsell_already_called_for_package') > 0, 'Repetitive',
                     'Other') AS upsell_status,
             anyIf(ineligibility_reason, ineligibility_reason LIKE 'ineligible_for_%') AS ineligible_reason,
             max(master_options_displayed_count > 1 OR slave_options_displayed_count > 1) AS has_options_displayed,
             max((master_gds_upsell_count + slave_gds_upsell_count) > 0) AS has_gds_options,
             argMax(tuple(no_options_reason), timestamp_micro).1 AS no_options_reason,
             argMax(tuple(gds_no_options_reason), timestamp_micro).1 AS gds_no_options_reason,
             max(is_upgraded_package) AS is_upgraded_package,
             max(is_eligible) AS is_eligible,
             argMax(tuple(is_synthetic), timestamp_micro).1 AS is_synthetic,
             max(has_atpco_features) AS has_atpco_features,
             argMax(tuple(atpco_error), timestamp_micro).1 AS atpco_error,
             argMax(tuple(master_upgrade_source), timestamp_micro).1 AS master_upgrade_source,
             argMax(tuple(slave_upgrade_source), timestamp_micro).1 AS slave_upgrade_source,
             any(device_type) AS device_type,
             any(site_id) AS site_id,
             any(affiliate_id) AS affiliate_id,
             argMax(upper(currency), timestamp_micro) AS currency,
             any(trip_type) AS trip_type,
             argMax(is_multiticket, timestamp_micro) AS is_multiticket,
             any(master_marketing_carriers) AS master_marketing_carriers,
             any(slave_marketing_carriers) AS slave_marketing_carriers,
             any(master_operating_carriers) AS master_operating_carriers,
             any(slave_operating_carriers) AS slave_operating_carriers,
             any(master_validating_carrier) AS master_validating_carrier,
             any(slave_validating_carrier) AS slave_validating_carrier,
             any(original_master_gds) AS original_master_gds,
             any(original_slave_gds) AS original_slave_gds,
             argMax(tuple(current_master_gds), timestamp_micro).1 AS current_master_gds,
             argMax(tuple(current_slave_gds), timestamp_micro).1 AS current_slave_gds,
             any(original_master_office_id) AS original_master_office_id,
             any(original_slave_office_id) AS original_slave_office_id,
             argMax(tuple(current_master_office_id), timestamp_micro).1 AS current_master_office_id,
             argMax(tuple(current_slave_office_id), timestamp_micro).1 AS current_slave_office_id,
             any(original_master_target_id) AS original_master_target_id,
             any(original_slave_target_id) AS original_slave_target_id,
             argMax(tuple(original_air_revenue), timestamp_micro).1 AS original_air_revenue,
             argMax(tuple(current_air_revenue), timestamp_micro).1 AS current_air_revenue
           FROM upsells.fare_family_upgrade_options_event
           WHERE context = 'checkout'
             AND checkout_id NOT IN ('', 'undefined') AND checkout_id IS NOT NULL
             AND {% condition fare_family_checkouts.checkout_date %} timestamp {% endcondition %}
           GROUP BY checkout_id
         ),
         bookings AS (
           SELECT event_key AS booked_event_key, max(booking_id) AS package_booking_id
           FROM upsells.fare_family_upgrade_options_event
           WHERE context = 'post-booking' AND booking_id > 0
           GROUP BY event_key
         )
         SELECT
           checkouts.*,
           if(bookings.package_booking_id > 0
                AND checkouts.last_event_at = max(checkouts.last_event_at) OVER (PARTITION BY checkouts.event_key),
              bookings.package_booking_id, NULL) AS booking_id
         FROM checkouts
         LEFT JOIN bookings ON checkouts.event_key = bookings.booked_event_key ;;
  }

  # ------------------------------------------------------------------
  # Identifiers
  # ------------------------------------------------------------------

  dimension: checkout_id {
    primary_key: yes
    type: string
    sql: ${TABLE}.checkout_id ;;
    group_label: "01. Identifiers"
    label: "Checkout ID"
    description: "Checkout id. One row per checkout."
  }

  dimension: booking_id {
    type: number
    sql: ${TABLE}.booking_id ;;
    value_format_name: id
    group_label: "13. Bookings"
    label: "Booking ID"
    description: "Booking (ota.bookings.id) from the post-booking event, credited to the last checkout of the booked package (same search + package). Empty on every other checkout."
  }

  dimension: is_booked {
    type: yesno
    sql: ${TABLE}.booking_id IS NOT NULL ;;
    group_label: "13. Bookings"
    label: "Is Booked"
    description: "Yes when this checkout is credited with a booking (the last checkout of a booked package)."
  }

  dimension: event_count {
    type: number
    sql: ${TABLE}.event_count ;;
    group_label: "01. Identifiers"
    label: "Event Count"
    description: "Number of checkout events in this checkout (1 for ~95%)."
  }

  # ------------------------------------------------------------------
  # Timestamps (America/New_York — server timezone, no conversion)
  # ------------------------------------------------------------------

  dimension_group: checkout {
    type: time
    timeframes: [raw, time, hour, date, week, month, quarter, year]
    sql: ${TABLE}.checkout_at ;;
    group_label: "02. Timestamps"
    label: "Checkout"
    description: "Time of the checkout's first event, America/New_York."
  }

  # ------------------------------------------------------------------
  # Attributes
  # ------------------------------------------------------------------

  dimension: checkout_upsell_status {
    type: string
    sql: ${TABLE}.upsell_status ;;
    group_label: "04. Eligibility"
    label: "Checkout Upsell Status"
    description: "One status per checkout. Upgraded = upgraded during checkout; Fresh = upsell called at checkout; Ineligible = ineligible_for_*; Repetitive = cached re-render only. Priority in that order. Statuses do not overlap and add up to 100%."
    suggestions: ["Upgraded", "Fresh", "Ineligible", "Repetitive"]
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

  dimension: device_type {
    type: string
    sql: ${TABLE}.device_type ;;
    group_label: "03. Context & Attributes"
    label: "Device Type"
    description: "desktop, mobile, mobile_app, tablet."
    suggestions: ["desktop", "mobile", "mobile_app", "tablet"]
  }

  dimension: site_id {
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
    sql: ${TABLE}.currency ;;
    group_label: "03. Context & Attributes"
    label: "Currency"
    description: "Display currency on the checkout's last event, upper-cased (source sends both USD and usd)."
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
    description: "Multi-ticket combination (master + slave tickets), on the checkout's last event."
  }

  dimension: is_upgraded_package {
    type: yesno
    sql: ${TABLE}.is_upgraded_package ;;
    group_label: "03. Context & Attributes"
    label: "Is Upgraded Package"
    description: "Yes when any event of the checkout is for an already-upgraded package (source flag). For upgraded counts use Checkout Upsell Status = Upgraded."
  }

  dimension: is_synthetic {
    type: yesno
    sql: ${TABLE}.is_synthetic ;;
    group_label: "03. Context & Attributes"
    label: "Is Synthetic"
    description: "Synthetic upgrade selection, on the checkout's last event."
  }

  dimension: is_eligible {
    type: yesno
    sql: ${TABLE}.is_eligible ;;
    group_label: "04. Eligibility"
    label: "Is Eligible"
    description: "Source flag, Yes when any event of the checkout is eligible to call the content source for fare-family upgrade options."
  }

  dimension: ineligible_reason {
    type: string
    sql: ${TABLE}.ineligible_reason ;;
    group_label: "04. Eligibility"
    label: "Ineligible Reason"
    description: "The ineligible_for_* reason when Checkout Upsell Status = Ineligible (inl, tablets, bus / train, carrier, currency, mixed fare family). Empty otherwise."
  }

  dimension: no_options_reason {
    type: string
    sql: ${TABLE}.no_options_reason ;;
    group_label: "04. Eligibility"
    label: "No Options Reason"
    description: "Why no fare-family options were displayed, on the checkout's last event. Empty when options were displayed."
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
    description: "Why the content source returned no options, on the checkout's last event."
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

  dimension: has_options_displayed {
    type: yesno
    sql: ${TABLE}.has_options_displayed ;;
    group_label: "06. Options"
    label: "Has Options Available"
    description: "Yes when the customer could choose an upgrade in this checkout: more than 1 fare family displayed on master or slave on any event. A count of 1 is the original fare only."
  }

  dimension: has_gds_options {
    type: yesno
    sql: ${TABLE}.has_gds_options ;;
    group_label: "06. Options"
    label: "Has Options Returned"
    description: "Yes when the content source returned any upsell options on any event of the checkout. Counts options returned, not necessarily usable."
  }

  dimension: has_atpco_features {
    type: yesno
    sql: ${TABLE}.has_atpco_features ;;
    group_label: "04. Eligibility"
    label: "Has ATPCO Features"
    description: "Yes when any event of the checkout has ATPCO fare-family feature data."
  }

  dimension: atpco_error {
    type: string
    sql: ${TABLE}.atpco_error ;;
    group_label: "04. Eligibility"
    label: "ATPCO Error"
    description: "ATPCO error on the checkout's last event, if any."
  }

  dimension: master_upgrade_source {
    type: string
    sql: ${TABLE}.master_upgrade_source ;;
    group_label: "05. Upgrade Source"
    label: "Master Upgrade Source"
    description: "Upgrade source for the master ticket, on the checkout's last event."
  }

  dimension: slave_upgrade_source {
    type: string
    sql: ${TABLE}.slave_upgrade_source ;;
    group_label: "05. Upgrade Source"
    label: "Slave Upgrade Source"
    description: "Upgrade source for the slave ticket (multi-ticket), on the checkout's last event."
  }

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
    description: "GDS of the current / upgraded package (master), on the checkout's last event."
  }

  dimension: current_slave_gds {
    type: string
    sql: ${TABLE}.current_slave_gds ;;
    group_label: "09. GDS Routing"
    label: "Current Slave GDS"
    description: "GDS of the current / upgraded package (slave), on the checkout's last event."
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
    description: "Office id of the current / upgraded package (master), on the checkout's last event."
  }

  dimension: current_slave_office_id {
    type: string
    sql: ${TABLE}.current_slave_office_id ;;
    group_label: "09. GDS Routing"
    label: "Current Slave Office ID"
    description: "Office id of the current / upgraded package (slave), on the checkout's last event."
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

  dimension: original_air_revenue {
    type: number
    sql: ${TABLE}.original_air_revenue ;;
    value_format_name: decimal_2
    group_label: "10. Revenue"
    label: "Original Air Revenue"
    description: "Air revenue before upgrade, on the checkout's last event. Median ~10 CAD / ~4 USD; can be negative. Unit unconfirmed: likely our margin on the air part, not the fare."
  }

  dimension: current_air_revenue {
    type: number
    sql: ${TABLE}.current_air_revenue ;;
    value_format_name: decimal_2
    group_label: "10. Revenue"
    label: "Current Air Revenue"
    description: "Air revenue after upgrade, on the checkout's last event. Can be negative. Unit unconfirmed: likely our margin on the air part, not the fare."
  }

  # ------------------------------------------------------------------
  # Measures — one row per checkout, so plain count / sum.
  # ------------------------------------------------------------------

  measure: checkouts_nbr {
    type: count
    group_label: "12. Coverage Funnel"
    label: "Checkout #"
    description: "Number of checkouts (checkout context)."
    drill_fields: [checkout_id, checkout_time, checkout_upsell_status, device_type, original_master_gds]
  }

  measure: checkouts_with_options_nbr {
    type: count
    filters: [has_options_displayed: "yes"]
    group_label: "12. Coverage Funnel"
    label: "Checkouts with Options Available #"
    description: "Checkouts where the customer could choose an upgrade (more than the original fare displayed)."
  }

  measure: checkouts_with_options_pct {
    type: number
    sql: 1.0 * ${checkouts_with_options_nbr} / NULLIF(${checkouts_nbr}, 0) ;;
    value_format_name: percent_2
    group_label: "12. Coverage Funnel"
    label: "Checkouts with Options Available %"
    description: "Checkouts with Options Available # / Checkout #. New-table metric; not comparable to board 1518 coverage."
  }

  measure: checkouts_with_options_returned_nbr {
    type: count
    filters: [has_gds_options: "yes"]
    group_label: "12. Coverage Funnel"
    label: "Checkouts with Options Returned #"
    description: "Checkouts where the content source returned upsell options (before display filtering)."
  }

  measure: checkouts_with_options_returned_pct {
    type: number
    sql: 1.0 * ${checkouts_with_options_returned_nbr} / NULLIF(${checkouts_nbr}, 0) ;;
    value_format_name: percent_2
    group_label: "12. Coverage Funnel"
    label: "Checkouts with Options Returned %"
    description: "Checkouts with Options Returned # / Checkout #. Counts returned options, not necessarily usable ones."
  }

  measure: upgraded_checkouts_nbr {
    type: count
    filters: [checkout_upsell_status: "Upgraded"]
    group_label: "12. Coverage Funnel"
    label: "Upgraded Checkout #"
    description: "Checkouts where the customer upgraded (Checkout Upsell Status = Upgraded)."
  }

  measure: upgraded_checkouts_pct {
    type: number
    sql: 1.0 * ${upgraded_checkouts_nbr} / NULLIF(${checkouts_nbr}, 0) ;;
    value_format_name: percent_2
    group_label: "12. Coverage Funnel"
    label: "Upgraded Checkout %"
    description: "Upgraded Checkout # / Checkout #."
  }

  measure: bookings_nbr {
    type: count_distinct
    sql: ${booking_id} ;;
    group_label: "13. Bookings"
    label: "Booking #"
    description: "Completed customer bookings (post-booking event), one checkout each. Multi-ticket counts once (master leg). Covers ~99% of MySQL bookings with checkout_status = booked, is_test = 0, sites 1 and 4, excluding aborted / unconfirmed_segments / multiticket_booking_fail cancels and slave legs. Includes ~1% test bookings."
  }

  measure: bookings_pct {
    type: number
    sql: 1.0 * ${bookings_nbr} / NULLIF(${checkouts_nbr}, 0) ;;
    value_format_name: percent_2
    group_label: "13. Bookings"
    label: "Booking %"
    description: "Booking # / Checkout #: bookings per checkout."
  }

  # Why (2026-09-25, FM): unit unconfirmed. Values look like our margin on the air
  # part, not the fare: median 9.85 CAD / 3.80 USD; 13% CAD / 28% USD checkout
  # events are below 0 (2026-09-22 NY). Drop "(unconfirmed)" once the source owner confirms.
  measure: booked_original_air_revenue_amt {
    type: sum
    sql: ${original_air_revenue} ;;
    filters: [is_booked: "yes"]
    value_format_name: decimal_2
    group_label: "10. Revenue"
    label: "Booked Original Air Revenue $ (unconfirmed)"
    description: "Original air revenue of booked checkouts. Group by Currency; do not add currencies together. Can be negative."
  }

  measure: booked_current_air_revenue_amt {
    type: sum
    sql: ${current_air_revenue} ;;
    filters: [is_booked: "yes"]
    value_format_name: decimal_2
    group_label: "10. Revenue"
    label: "Booked Current Air Revenue $ (unconfirmed)"
    description: "Current (after upgrade) air revenue of booked checkouts. Group by Currency; do not add currencies together. Can be negative."
  }

  measure: booked_air_revenue_uplift_amt {
    type: sum
    sql: ${current_air_revenue} - ${original_air_revenue} ;;
    filters: [is_booked: "yes"]
    value_format_name: decimal_2
    group_label: "10. Revenue"
    label: "Booked Air Revenue Uplift $ (unconfirmed)"
    description: "Current minus original air revenue of booked checkouts: the gain from upgrades. Group by Currency; do not add currencies together."
  }
}
