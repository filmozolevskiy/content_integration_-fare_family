view: upgrade_attempts {
  derived_table: {
    sql:
      WITH upgrade_bounds AS (
        SELECT
          customer_attempt_id,
          MIN(id) AS min_id_for_master,
          MAX(id) AS max_id_for_slave
        FROM bookability_customer_attempt_upgrade_option
        GROUP BY customer_attempt_id
        ),

        contestants_with_match_id AS (
        SELECT
          bca.*,
          bcusta.affiliate_id,
          CASE
            WHEN bca.multiticket_part = 'master' THEN ub.min_id_for_master
            WHEN bca.multiticket_part = 'slave' THEN ub.max_id_for_slave
            ELSE ub.min_id_for_master
          END AS match_id
        FROM bookability_contestant_attempts bca
        JOIN upgrade_bounds ub ON bca.customer_attempt_id = ub.customer_attempt_id
        JOIN bookability_customer_attempts bcusta on bcusta.id = bca.customer_attempt_id
        WHERE bca.date_created >= CURDATE() - INTERVAL 1 DAY
        ),
        exchange_rate AS (
        select
          id AS booking_id,
          currency,
          exchange_rate
        from bookings
        )
        SELECT
          cwm.date_created AS date_created,
          cwm.search_hash,
          cwm.package_hash,
          cwm.booking_id,
          cwm.original_revenue,
          cwm.status AS status,
          cwm.gds,
          cwm.office_id,
          cwm.currency,
          er.exchange_rate,
          cwm.fare_type,
          cwm.validating_carrier,
          cwm.marketing_carriers,
          cwm.multiticket_part,
          cwm.exception,
          cwm.gds_error_message,
          cwm.affiliate_id
        FROM contestants_with_match_id cwm
        JOIN bookability_customer_attempt_upgrade_option bcauo
        ON bcauo.customer_attempt_id = cwm.customer_attempt_id
        AND bcauo.id = cwm.match_id
        JOIN bookability_customer_attempts bcusta
        ON bcusta.id = cwm.customer_attempt_id
        JOIN exchange_rate er
        ON er.booking_id = cwm.booking_id
        ;;
  }

  dimension_group: date_created {
    type: time
    timeframes: [raw,hour, date, week, month, year]
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

  dimension: affiliate_id {
    type: number
    sql: ${TABLE}.affiliate_id ;;
  }

  dimension: booking_id {
    type: string
    sql: ${TABLE}.booking_id ;;
  }

  dimension: revenue {
    type: number
    sql: ${TABLE}.original_revenue ;;
  }

  dimension: exchange_rate {
    type: number
    sql: ${TABLE}.exchange_rate ;;
  }

  dimension: revenue_cad {
    type: number
    label: "Revenue (CAD, row)"
    sql:
    CASE
      WHEN ${exchange_rate} IS NOT NULL THEN ${revenue} * ${exchange_rate}
      WHEN ${currency} = 'CAD' THEN ${revenue}
      ELSE NULL
    END ;;
    value_format: "$#,##0.00"
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
        WHEN ${TABLE}.multiticket_part = 'master' THEN true
        ELSE false
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


#### MEASURES ####


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

  measure: booking_revenue_sum {
    type: sum
    sql: ${revenue} ;;
    value_format_name: decimal_0
    label: "Booking Revenue"
  }

  measure: booking_revenue_sum_cad {
    type: sum
    sql:
    CASE
      WHEN ${exchange_rate} IS NOT NULL THEN ${revenue} * ${exchange_rate}
      WHEN ${currency} = 'CAD' THEN ${revenue}
      ELSE NULL
    END ;;
    label: "Booking Revenue (CAD)"
    value_format: "$#,##0"
  }

}
