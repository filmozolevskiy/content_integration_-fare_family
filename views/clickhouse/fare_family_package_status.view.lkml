view: fare_family_package_status {
  # One row per package (event_key = one search + one package) in checkout context
  # (Trello #3121). A booking links to exactly one package, so Booking # grouped by
  # Package Upsell Status adds up to Booking # (6,552 on 2026-09-22 NY). Checkout
  # Upsell Status does not: one package can hold checkouts with different statuses.
  # Same priority rule as fare_family_checkout_status.
  # Revenue = value on the package's last checkout event (argMax by timestamp_micro),
  # so a package counts once even with several checkouts.
  # Ephemeral SQL derived table — no datagroup_trigger (clickhouse-prod rejects PDTs).
  derived_table: {
    sql: SELECT event_key,
                multiIf(countIf(ineligibility_reason = 'upsell_already_called_for_upgraded_package') > 0, 'Upgraded',
                        countIf(ineligibility_reason IS NULL) > 0, 'Fresh',
                        countIf(ineligibility_reason LIKE 'ineligible_for_%') > 0, 'Ineligible',
                        countIf(ineligibility_reason = 'upsell_already_called_for_package') > 0, 'Repetitive',
                        'Other') AS package_upsell_status,
                argMax(original_air_revenue, timestamp_micro) AS original_air_revenue,
                argMax(current_air_revenue, timestamp_micro) AS current_air_revenue
         FROM upsells.fare_family_upgrade_options_event
         WHERE context = 'checkout'
           AND checkout_id NOT IN ('', 'undefined') AND checkout_id IS NOT NULL
           AND {% condition fare_family_events.timestamp_date %} timestamp {% endcondition %}
         GROUP BY event_key ;;
  }

  dimension: event_key {
    primary_key: yes
    hidden: yes
    type: string
    sql: ${TABLE}.event_key ;;
  }

  dimension: package_upsell_status {
    type: string
    sql: ${TABLE}.package_upsell_status ;;
    group_label: "04. Eligibility"
    label: "Package Upsell Status"
    description: "One status per package (search + package), over all its checkout events. Upgraded > Fresh > Ineligible > Repetitive. Use with Booking #, Booked Package #, Checkout Package #: they add up to the total."
    suggestions: ["Upgraded", "Fresh", "Ineligible", "Repetitive"]
  }

  dimension: package_original_air_revenue {
    hidden: yes
    type: number
    sql: ${TABLE}.original_air_revenue ;;
  }

  dimension: package_current_air_revenue {
    hidden: yes
    type: number
    sql: ${TABLE}.current_air_revenue ;;
  }

  # Why (2026-09-25, FM): unit unconfirmed. Values look like our margin on the air
  # part, not the fare: median 9.85 CAD / 3.80 USD, and 13% CAD / 28% USD checkout
  # events are below 0 (2026-09-22 NY). Confirm with the source owner, then drop
  # "(unconfirmed)" from the labels.
  measure: booked_original_air_revenue_amt {
    type: sum
    sql: ${package_original_air_revenue} ;;
    filters: [fare_family_booking_lookup.is_booked: "yes"]
    value_format_name: decimal_2
    group_label: "10. Revenue"
    label: "Booked Original Air Revenue $ (unconfirmed)"
    description: "Original air revenue of booked packages, one value per package. Group by Currency; do not add currencies together. Unit unconfirmed; can be negative."
  }

  measure: booked_current_air_revenue_amt {
    type: sum
    sql: ${package_current_air_revenue} ;;
    filters: [fare_family_booking_lookup.is_booked: "yes"]
    value_format_name: decimal_2
    group_label: "10. Revenue"
    label: "Booked Current Air Revenue $ (unconfirmed)"
    description: "Current (after upgrade) air revenue of booked packages, one value per package. Group by Currency; do not add currencies together. Unit unconfirmed; can be negative."
  }

  measure: booked_air_revenue_uplift_amt {
    type: sum
    sql: ${package_current_air_revenue} - ${package_original_air_revenue} ;;
    filters: [fare_family_booking_lookup.is_booked: "yes"]
    value_format_name: decimal_2
    group_label: "10. Revenue"
    label: "Booked Air Revenue Uplift $ (unconfirmed)"
    description: "Current minus original air revenue of booked packages: the gain from upgrades. Group by Currency; do not add currencies together. Unit unconfirmed."
  }
}
