view: upgrade_attempts {
  derived_table: {
    sql:
      SELECT
        bca.date_created AS date_created,
        bca.search_hash,
        bca.package_hash,
        bca.booking_id,
        bca.status AS status,
        bca.gds,
        bca.office_id,
        bca.currency,
        bca.fare_type,
        bca.validating_carrier,
        bca.marketing_carriers,
        bca.multiticket_part,
        bca.exception,
        bca.gds_error_message
      FROM bookability_contestant_attempts bca
      JOIN bookability_customer_attempt_upgrade_option bcauo
        ON bcauo.customer_attempt_id = bca.customer_attempt_id
      WHERE
        bca.date_created >= subtractDays(today(), 30)
      ;;
  }

  dimension_group: date_created {
    type: time
    timeframes: [raw, date, week, month, year]
    sql: ${TABLE}.date_created ;;
  }

  dimension: search_hash {
    type: string
    sql: ${TABLE}.search_hash ;;
  }

  dimension: package_hash {
    type: string
    sql: ${TABLE}.package_hash ;;
  }

  dimension: booking_id {
    type: string
    sql: ${TABLE}.booking_id ;;
  }

  dimension: status {
    type: number
    sql: ${TABLE}.status ;;
  }

  dimension: gds {
    type: string
    sql: ${TABLE}.gds ;;
  }

  dimension: office_id {
    type: string
    sql: ${TABLE}.office_id ;;
  }

  dimension: currency {
    type: string
    sql: ${TABLE}.currency ;;
  }

  dimension: fare_type {
    type: string
    sql: ${TABLE}.fare_type ;;
  }

  dimension: validating_carrier {
    type: string
    sql: ${TABLE}.validating_carrier ;;
  }

  dimension: marketing_carriers {
    type: string
    sql: ${TABLE}.marketing_carriers ;;
  }

  dimension: multiticket_part {
    type: string
    sql: ${TABLE}.multiticket_part ;;
  }

  dimension: exception {
    type: string
    sql: ${TABLE}.exception ;;
  }

  dimension: gds_error_message {
    type: string
    sql: ${TABLE}.gds_error_message ;;
  }

  measure: failed_attempts {
    type: count
    value_format_name: decimal_0
  }
}
