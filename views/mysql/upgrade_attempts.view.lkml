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
      WHERE date_created >= CURDATE() - INTERVAL 30 DAY
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

  dimension: is_multiticket {
    type: yesno
    sql: CASE
        WHEN ${TABLE}.multiticket_part = 'master' THEN YES
        ELSE NO
       END ;;
  }

  dimension: exception {
    type: string
    sql: ${TABLE}.exception ;;
  }

  dimension: gds_error_message {
    type: string
    sql: ${TABLE}.gds_error_message ;;
  }

  measure: successful_attempts {
    type: sum
    sql: CASE WHEN ${status} = 1 THEN 1 ELSE 0 END ;;
    value_format_name: decimal_0
    label: "Successful Attempts"
  }

  measure: failed_attempts {
    type: sum
    sql: CASE WHEN ${status} = 0 THEN 1 ELSE 0 END ;;
    value_format_name: decimal_0
    label: "Failed Attempts"
  }

  measure: total_attempts {
    type: count
    value_format_name: decimal_0
    label: "Total Attempts"
  }

  measure: success_rate {
    type: number
    sql: CASE WHEN ${total_attempts} = 0 THEN NULL ELSE ${successful_attempts} * 1.0 / ${total_attempts} END ;;
    value_format_name: percent_2
    label: "Success Rate"
  }

  measure: failure_rate {
    type: number
    sql: CASE WHEN ${total_attempts} = 0 THEN NULL ELSE ${failed_attempts} * 1.0 / ${total_attempts} END ;;
    value_format_name: percent_2
    label: "Failure Rate"
  }

  measure: multiticket_count {
    type: sum
    sql: CASE
        WHEN ${is_multiticket} THEN 1
        ELSE 0
       END ;;
    value_format_name: decimal_0
    label: "Multiticket Count"
  }


}
