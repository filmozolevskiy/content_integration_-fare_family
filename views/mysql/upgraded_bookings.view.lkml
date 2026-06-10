view: upgraded_bookings {
  derived_table: {
    sql:
      SELECT
        b.booking_date,
        b.id,
        bd.is_upgraded_package,
        b.validating_carrier,
        b.multiticket_relationship_type,
        b.cancel_reason,
        b.currency,
        b.exchange_rate,
        bd.affiliate_id,
        bca.original_revenue as revenue
      FROM
        bookings b
        JOIN booking_details bd ON b.id = bd.booking_id
        JOIN bookability_contestant_attempts bca
          ON bca.booking_id = b.id
          AND bca.office_id = b.gds_account_id
      WHERE
        b.booking_date >= CURDATE() - INTERVAL 60 DAY
        AND EXISTS (SELECT 1 FROM booking_tasks WHERE booking_id = b.id AND type = 1)
        AND b.is_test = 0
        AND bca.source not like '%staging%'
        AND (b.is_multiticket = 0 OR b.multiticket_relationship_type = 'master')
        AND (b.cancel_reason IS NULL OR b.cancel_reason IN ('customer_request', 'aborted', 'cc_decline', 'fraud'))
    ;;
  }

  dimension_group: booking_date {
    type: time
    timeframes: [raw, hour, date, week, month, year]
    sql: ${TABLE}.booking_date ;;
    group_label: "1. Date"
    label: "Booking Date"
    description: "Date the booking was created."
  }

  dimension: booking_id {
    type: number
    primary_key: yes
    sql: ${TABLE}.id ;;
    group_label: "2. Booking"
    label: "Booking ID"
    description: "Unique booking identifier (bookings.id)."
  }

  dimension: is_upgraded_package {
    type: yesno
    sql: ${TABLE}.is_upgraded_package ;;
    group_label: "2. Booking"
    label: "Is Upgraded Package"
    description: "True when the booking used an upgraded (fare family) package."
  }

  dimension: cancel_reason {
    type: string
    sql: ${TABLE}.cancel_reason ;;
    group_label: "2. Booking"
    label: "Cancel Reason"
    description: "Reason the booking was cancelled; NULL for active bookings."
  }

  dimension: affiliate_id {
    type: number
    sql: ${TABLE}.affiliate_id ;;
    group_label: "2. Booking"
    label: "Affiliate ID"
    description: "Affiliate identifier from booking_details."
  }

  dimension: validating_carrier {
    type: string
    sql: ${TABLE}.validating_carrier ;;
    group_label: "3. Flight"
    label: "Validating Carrier"
    description: "IATA code of the validating carrier."
  }

  dimension: multiticket_relationship_type {
    type: string
    sql: ${TABLE}.multiticket_relationship_type ;;
    group_label: "3. Flight"
    label: "Multiticket Relationship Type"
    description: "Multiticket role: 'master', 'slave', or NULL for single-ticket bookings."
  }

  dimension: currency {
    type: string
    sql: ${TABLE}.currency ;;
    group_label: "4. Revenue"
    label: "Currency"
    description: "Booking currency code."
  }

  dimension: exchange_rate {
    type: number
    sql: ${TABLE}.exchange_rate ;;
    group_label: "4. Revenue"
    label: "Exchange Rate"
    description: "Exchange rate from booking currency to CAD at time of booking."
    hidden: yes
  }

  dimension: revenue {
    type: number
    sql: ${TABLE}.revenue ;;
    value_format_name: decimal_2
    label: "Revenue"
    group_label: "4. Revenue"
    description: "Original revenue from the winning contestant attempt."
  }

  dimension: revenue_cad {
    type: number
    sql:
      CASE
        WHEN ${exchange_rate} IS NOT NULL THEN ${revenue} * ${exchange_rate}
        WHEN ${currency} = 'CAD'           THEN ${revenue}
        ELSE NULL
      END ;;
    value_format: "$#,##0.00"
    label: "Revenue (CAD, row)"
    group_label: "4. Revenue"
    description: "Per-booking revenue converted to CAD; NULL when rate and currency are unknown."
  }

  measure: total_bookings {
    type: count
    value_format_name: decimal_0
    label: "Total Bookings"
    group_label: "2. Booking"
    description: "Total number of bookings in the 60-day window."
  }

  measure: upgraded_bookings_count {
    type: count
    filters: [
      is_upgraded_package: "yes"
    ]
    label: "Upgraded Bookings"
    group_label: "2. Booking"
    description: "Number of bookings where an upgraded package was used."
  }

  measure: nk_bundles_count {
    type: count
    filters: [
      is_upgraded_package: "yes",
      validating_carrier: "NK"
    ]
    value_format_name: decimal_0
    label: "NK Bundles"
    group_label: "2. Booking"
    description: "Count of upgraded bookings on Spirit Airlines (NK)."
  }

  measure: f9_bundles_count {
    type: count
    filters: [
      is_upgraded_package: "yes",
      validating_carrier: "F9"
    ]
    value_format_name: decimal_0
    label: "F9 Bundles"
    group_label: "2. Booking"
    description: "Count of upgraded bookings on Frontier Airlines (F9)."
  }

  measure: pd_bundles_count {
    type: count
    filters: [
      is_upgraded_package: "yes",
      validating_carrier: "PD"
    ]
    value_format_name: decimal_0
    label: "PD Bundles"
    group_label: "2. Booking"
    description: "Count of upgraded bookings on Porter Airlines (PD)."
  }

  measure: upgraded_bookings_percentage {
    type: number
    sql: ${upgraded_bookings_count} / NULLIF(${total_bookings}, 0) ;;
    value_format: "0.0%"
    label: "Upgraded Bookings %"
    group_label: "2. Booking"
    description: "Proportion of total bookings that used an upgraded package."
  }

  measure: multiticket_bookings_count {
    type: count
    filters: [
      multiticket_relationship_type: "master",
      is_upgraded_package: "yes"
    ]
    value_format_name: decimal_0
    label: "Multiticket Upgraded Bookings"
    group_label: "3. Flight"
    description: "Count of upgraded bookings that are master legs of multiticket itineraries."
  }

  measure: regular_bookings_count {
    type: count
    filters: [
      multiticket_relationship_type: "-master",
      is_upgraded_package: "yes"
    ]
    value_format_name: decimal_0
    label: "Single-Ticket Upgraded Bookings"
    group_label: "3. Flight"
    description: "Count of upgraded bookings that are single-ticket (non-master multiticket)."
  }

  measure: total_revenue {
    type: sum
    sql: ${revenue} ;;
    value_format_name: decimal_2
    label: "Total Revenue"
    group_label: "4. Revenue"
    description: "Sum of revenue across all bookings in the window."
  }

  measure: upgraded_revenue {
    type: sum
    sql: ${revenue} ;;
    filters: [
      is_upgraded_package: "yes"
    ]
    value_format_name: decimal_2
    label: "Upgraded Revenue"
    group_label: "4. Revenue"
    description: "Sum of revenue from bookings that used an upgraded package, in booking currency."
  }

  measure: upgraded_revenue_cad {
    type: sum
    sql: ${revenue_cad} ;;
    filters: [
      is_upgraded_package: "yes"
    ]
    value_format: "$#,##0"
    label: "Upgraded Revenue (CAD)"
    group_label: "4. Revenue"
    description: "Sum of revenue from bookings that used an upgraded package, converted to CAD."
  }

  measure: upgrade_revenue_per_booking_cad {
    type: number
    sql: ${upgraded_revenue_cad} / NULLIF(${total_bookings}, 0) ;;
    value_format: "$#,##0.00"
    label: "Upgrade Revenue per Booking (CAD)"
    group_label: "4. Revenue"
    description: "Upgraded revenue (CAD) divided by total bookings in the same slice — volume-normalised upgrade revenue."
  }

}
