view: upgraded_bookings {
  derived_table: {
    sql:
      SELECT
        b.booking_date as booking_date,
        b.id as id,
        bd.is_upgraded_package as is_upgraded_package,
        b.multiticket_relationship_type as multiticket_relationship_type,
        b.cancel_reason as cancel_reason
      FROM bookings b
      JOIN booking_details bd ON b.id = bd.booking_id
      WHERE
        b.booking_date BETWEEN  @start AND @end
        and (b.multiticket_relationship_type = ('master')
          or b.multiticket_relationship_type is null)
        and (b.cancel_reason is null
          or b.cancel_reason = 'customer_request')
        and is_test = 0
        and date_created >= CURDATE() - INTERVAL 30 DAY
      ;;
  }

  dimension: booking_date {
    type: date
    sql: ${TABLE}.booking_date ;;
  }

  dimension: booking_id {
    type: number
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
    sql: ${booking_id} ;;
  }

  measure: upgraded_bookings_count {
    type: count
    sql: CASE WHEN ${is_upgraded_package} THEN ${booking_id} END ;;
  }

  measure: upgraded_bookings_percentage {
    type: number
    sql: ${upgraded_bookings_count} / NULLIF(${total_bookings}, 0) ;;
    value_format: "0.0%"
  }



  }
