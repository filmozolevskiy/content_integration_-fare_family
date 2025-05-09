view: upgraded_bookings {
  derived_table: {
    sql:
      SELECT
        b.booking_date,
        b.id,
        bd.is_upgraded_package,
        b.multiticket_relationship_type,
        b.cancel_reason
      FROM
        bookings b
        JOIN booking_details bd ON b.id = bd.booking_id
      WHERE
        b.booking_date >= CURDATE() - INTERVAL 30 DAY
        AND EXISTS (SELECT 1 FROM booking_tasks WHERE booking_id = b.id AND type = 1)
        AND b.is_test = 0
        AND (b.is_multiticket = 0 OR b.multiticket_relationship_type = 'master')
        AND (b.cancel_reason IS NULL OR b.cancel_reason IN ('customer_request', 'aborted', 'cc_decline', 'fraud'))
      ;;
  }

  dimension_group: booking_date {
    type: time
    timeframes: [raw, date, week, month, year]
    sql: ${TABLE}.booking_date ;;
  }

  dimension: booking_id {
    type: number
    primary_key: yes
    sql: ${TABLE}.id ;;
  }

  dimension: is_upgraded_package {
    type: yesno
    sql: ${TABLE}.is_upgraded_package ;;
  }

  dimension: multiticket_relationship_type {
    type: string
    sql: ${TABLE}.multiticket_relationship_type ;;
  }

  dimension: cancel_reason {
    type: string
    sql: ${TABLE}.cancel_reason ;;
  }

  measure: total_bookings {
    type: count
    value_format_name: decimal_0
  }

  measure: upgraded_bookings_count {
    type: count
    filters:[
      is_upgraded_package: "yes"
      ]
  }

  measure: upgraded_bookings_percentage {
    type: number
    sql: ${upgraded_bookings_count} / NULLIF(${total_bookings}, 0) ;;
    value_format: "0.0%"
  }

}
