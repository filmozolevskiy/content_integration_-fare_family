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
        WHERE bca.date_created >= CURDATE() - INTERVAL 60 DAY
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
    timeframes: [raw, hour, date, week, month, year]
    sql: ${TABLE}.date_created ;;
    group_label: "1. Date"
    label: "Date Created"
    description: "Date/time the contestant attempt was created in bookability_contestant_attempts."
  }

  dimension: search_hash {
    type: string
    sql: ${TABLE}.search_hash ;;
    group_label: "2. Booking"
    label: "Search Hash"
    description: "Unique identifier for the search session."
  }

  dimension: package_hash {
    type: string
    sql: ${TABLE}.package_hash ;;
    group_label: "2. Booking"
    label: "Package Hash"
    description: "Unique identifier for the package within the search."
  }

  dimension: affiliate_id {
    type: number
    sql: ${TABLE}.affiliate_id ;;
    group_label: "2. Booking"
    label: "Affiliate ID"
    description: "Affiliate identifier from bookability_customer_attempts."
  }

  dimension: booking_id {
    type: string
    sql: ${TABLE}.booking_id ;;
    group_label: "2. Booking"
    label: "Booking ID"
    description: "ID of the associated booking in the bookings table."
  }

  dimension: status {
    type: number
    sql: ${TABLE}.status ;;
    group_label: "3. Attempt"
    label: "Status"
    description: "Attempt status: 1 = success, 0 = failure."
  }

  dimension: exception {
    type: string
    sql: ${TABLE}.exception ;;
    group_label: "3. Attempt"
    label: "Exception"
    description: "Exception thrown during the upgrade attempt, if any."
  }

  dimension: gds_error_message {
    type: string
    sql: ${TABLE}.gds_error_message ;;
    group_label: "3. Attempt"
    label: "GDS Error Message"
    description: "Error message returned by the GDS during the upgrade attempt."
  }

  dimension: gds {
    type: string
    sql: ${TABLE}.gds ;;
    group_label: "4. Flight"
    label: "GDS"
    description: "Global Distribution System used for this attempt."
  }

  dimension: office_id {
    type: string
    sql: ${TABLE}.office_id ;;
    group_label: "4. Flight"
    label: "Office ID"
    description: "GDS office ID used for the booking."
  }

  dimension: currency {
    type: string
    sql: ${TABLE}.currency ;;
    group_label: "4. Flight"
    label: "Currency"
    description: "Currency of the original revenue."
  }

  dimension: fare_type {
    type: string
    sql: ${TABLE}.fare_type ;;
    group_label: "4. Flight"
    label: "Fare Type"
    description: "Fare type of the upgraded offer."
  }

  dimension: validating_carrier {
    type: string
    sql: ${TABLE}.validating_carrier ;;
    group_label: "4. Flight"
    label: "Validating Carrier"
    description: "IATA code of the validating carrier."
  }

  dimension: marketing_carriers {
    type: string
    sql: ${TABLE}.marketing_carriers ;;
    group_label: "4. Flight"
    label: "Marketing Carriers"
    description: "IATA codes of marketing carriers on the itinerary."
  }

  dimension: multiticket_part {
    type: string
    sql: ${TABLE}.multiticket_part ;;
    group_label: "5. Multiticket"
    label: "Multiticket Part"
    description: "Whether this attempt is the master or slave leg of a multiticket booking."
  }

  dimension: is_multiticket {
    type: yesno
    sql: CASE
        WHEN ${TABLE}.multiticket_part = 'master' THEN true
        ELSE false
       END ;;
    group_label: "5. Multiticket"
    label: "Is Multiticket"
    description: "True when this attempt is the master leg of a multiticket booking."
  }

  dimension: revenue {
    type: number
    sql: ${TABLE}.original_revenue ;;
    group_label: "6. Revenue"
    label: "Revenue"
    description: "Original revenue of the contestant attempt in the booking currency."
  }

  dimension: exchange_rate {
    type: number
    sql: ${TABLE}.exchange_rate ;;
    group_label: "6. Revenue"
    label: "Exchange Rate"
    description: "Exchange rate from the booking currency to CAD at time of booking."
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
    group_label: "6. Revenue"
    description: "Revenue converted to CAD using the exchange rate; NULL if rate and currency are unknown."
  }


#### MEASURES ####


  measure: successful_attempts {
    type: sum
    sql: CASE WHEN ${status} = 1 THEN 1 ELSE 0 END ;;
    value_format_name: decimal_0
    label: "Successful Attempts"
    group_label: "3. Attempt"
    description: "Number of upgrade attempts that succeeded (status = 1)."
  }

  measure: failed_attempts {
    type: sum
    sql: CASE WHEN ${status} = 0 THEN 1 ELSE 0 END ;;
    value_format_name: decimal_0
    label: "Failed Attempts"
    group_label: "3. Attempt"
    description: "Number of upgrade attempts that failed (status = 0)."
  }

  measure: total_attempts {
    type: count
    value_format_name: decimal_0
    label: "Total Attempts"
    group_label: "3. Attempt"
    description: "Total number of upgrade contestant attempts in the window."
  }

  measure: success_rate {
    type: number
    sql: CASE WHEN ${total_attempts} = 0 THEN NULL ELSE ${successful_attempts} * 1.0 / ${total_attempts} END ;;
    value_format_name: percent_2
    label: "Success Rate"
    group_label: "3. Attempt"
    description: "Proportion of upgrade attempts that succeeded."
  }

  measure: failure_rate {
    type: number
    sql: CASE WHEN ${total_attempts} = 0 THEN NULL ELSE ${failed_attempts} * 1.0 / ${total_attempts} END ;;
    value_format_name: percent_2
    label: "Failure Rate"
    group_label: "3. Attempt"
    description: "Proportion of upgrade attempts that failed."
  }

  measure: multiticket_count {
    type: sum
    sql: CASE
        WHEN ${is_multiticket} THEN 1
        ELSE 0
       END ;;
    value_format_name: decimal_0
    label: "Multiticket Count"
    group_label: "5. Multiticket"
    description: "Number of upgrade attempts that are master legs of multiticket bookings."
  }

  measure: booking_revenue_sum {
    type: sum
    sql: CASE WHEN ${status} = 1 THEN ${revenue} ELSE 0 END ;;
    value_format_name: decimal_0
    label: "Booking Revenue"
    group_label: "6. Revenue"
    description: "Total revenue from successful upgrade attempts, in the booking currency."
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
    group_label: "6. Revenue"
    description: "Total revenue from upgrade attempts converted to CAD."
  }

}
