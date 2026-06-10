view: daily_bookings_total {
  derived_table: {
    sql:
      SELECT
        b.booking_date,
        COUNT(*) AS total_bookings
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
      GROUP BY b.booking_date
    ;;
  }

  dimension: booking_date {
    type: date
    primary_key: yes
    sql: ${TABLE}.booking_date ;;
    hidden: yes
  }

  dimension: total_bookings_per_day {
    type: number
    sql: ${TABLE}.total_bookings ;;
    hidden: yes
  }

  measure: total_bookings {
    type: sum_distinct
    sql_distinct_key: ${booking_date} ;;
    sql: ${total_bookings_per_day} ;;
    value_format_name: decimal_0
    label: "Total Bookings (Daily)"
    group_label: "2. Booking"
    description: "Total bookings on the attempt's day. Same filter set as upgraded_bookings.total_bookings (60-day window, non-test, non-staging, master / single-ticket, allowed cancel reasons). Uses sum_distinct on booking_date so the count is not inflated by fan-out from upgrade_attempts."
  }
}
