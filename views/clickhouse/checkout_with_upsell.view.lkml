view: checkout_with_upsell {
  derived_table: {
    sql:
      WITH
        total_checkouts AS (
          SELECT
            begin_checkout_timestamp,
            search_id,
            package_id,
            surfer_id,
            site_name,
            currency,
            affiliate_id,
            origin_airport,
            destination_airport,
            num_adults,
            num_children,
            num_infants,
            num_infants_seat,
            departure_date,
            return_date,
            flight_class,
            fare_class,
            trip_type,
            ROW_NUMBER() OVER (PARTITION BY search_id,package_id ORDER BY begin_checkout_timestamp DESC) AS rn
          FROM gtm_views.begin_checkout
        ),

        amadeus_upsell AS (
          SELECT
            created_at,
            search_id,
            package_id,
            error_code,
            error_message,
            offers_returned,
            validating_carriers,
            marketing_carriers,
            operating_carriers,
            gds_office_id,
            ROW_NUMBER() OVER (PARTITION BY search_id, package_id ORDER BY created_at DESC) AS rn
          FROM jupiter.jupiter_fare_priceupsellwithoutpnr
        ),

        routehappy AS (
          SELECT
            created_at,
            search_id,
            package_id,
            itineraries,
            error_message,
            scope,
            ROW_NUMBER() OVER (
            PARTITION BY search_id, package_id ORDER BY created_at DESC) AS rn
          FROM jupiter.jupiter_consolidated
          WHERE (scope = 'Upsells' or scope = '')
      ),

        final_step AS (
          SELECT
            created_at,
            search_id,
            package_id,
            is_eligible_for_upgrade,
            offers_returned,
            offers_shown,
            ROW_NUMBER() OVER (
            PARTITION BY search_id, package_id ORDER BY created_at DESC) AS rn
          FROM jupiter.jupiter_upsell_proposals
      )

      SELECT
      total_checkouts.begin_checkout_timestamp AS checkout_begin_checkout_timestamp,
      total_checkouts.search_id AS checkout_search_id,
      total_checkouts.package_id AS checkout_package_id,
      total_checkouts.surfer_id AS surfer_id,
      total_checkouts.site_name AS site_name,
      total_checkouts.currency AS currency,
      total_checkouts.affiliate_id AS affiliate_id,
      total_checkouts.origin_airport AS origin_airport,
      total_checkouts.destination_airport AS destination_airport,
      total_checkouts.num_adults AS num_adults,
      total_checkouts.num_children AS num_children,
      total_checkouts.num_infants AS num_infants,
      total_checkouts.num_infants_seat AS num_infants_seat,
      total_checkouts.departure_date AS departure_date,
      total_checkouts.return_date AS return_date,
      total_checkouts.flight_class AS flight_class,
      total_checkouts.fare_class AS fare_class,
      total_checkouts.trip_type AS trip_type,

      amadeus_upsell.created_at AS amadeus_created_at,
      NULLIF(amadeus_upsell.search_id, '') AS amadeus_search_id,
      NULLIF(amadeus_upsell.package_id, '') AS amadeus_package_id,
      amadeus_upsell.error_code AS amadeus_error_code,
      amadeus_upsell.error_message AS amadeus_error_message,
      amadeus_upsell.offers_returned AS amadeus_offers_returned,
      amadeus_upsell.validating_carriers AS amadeus_validating_carriers,
      amadeus_upsell.marketing_carriers AS amadeus_marketing_carriers,
      amadeus_upsell.operating_carriers AS amadeus_operating_carriers,
      amadeus_upsell.gds_office_id AS original_gds_office_id,

      routehappy.created_at AS routehapp_created_at,
      NULLIF(routehappy.search_id, '') AS routehapp_search_id,
      NULLIF(routehappy.package_id, '') AS routehapp_package_id,
      routehappy.itineraries AS routehapp_packages_sent,
      routehappy.error_message AS routehapp_errors,
      routehappy.scope as routehapp_scope,

      final_step.created_at AS final_step_created_at,
      NULLIF(final_step.search_id, '') AS final_step_search_id,
      NULLIF(final_step.package_id, '') AS final_step_package_id,
      final_step.is_eligible_for_upgrade AS is_eligible_for_upgrade,
      final_step.offers_returned AS final_step_offers_returned,
      final_step.offers_shown AS final_step_offers_shown

      FROM total_checkouts
      LEFT JOIN amadeus_upsell
      ON total_checkouts.search_id = amadeus_upsell.search_id
      AND total_checkouts.package_id = amadeus_upsell.package_id
      LEFT JOIN routehappy
      ON total_checkouts.search_id = routehappy.search_id
      AND total_checkouts.package_id = routehappy.package_id
      LEFT JOIN final_step
      ON total_checkouts.search_id = final_step.search_id
      AND total_checkouts.package_id = final_step.package_id

      WHERE total_checkouts.rn = 1
      AND (amadeus_upsell.rn = 1 OR amadeus_upsell.rn = 0)
      AND (routehappy.rn = 1 OR routehappy.rn = 0)
      AND (final_step.rn = 1 OR final_step.rn = 0)
      AND total_checkouts.begin_checkout_timestamp >= subtractDays(today(), 30)
      ;;
  }

  # 🎯 Dimensions organized by source table (group_label)

  # --- Checkout ---
  dimension_group: checkout_begin_checkout_timestamp {
    type: time
    timeframes: [raw, hour, date, week, month, quarter, year]
    sql: ${TABLE}.checkout_begin_checkout_timestamp ;;
    group_label: "1. Checkout"
  }

  dimension: checkout_search_id {
    primary_key: yes
    type: string
    sql: ${TABLE}.checkout_search_id ;;
    group_label: "1. Checkout"
  }

  dimension: checkout_package_id {
    type: string
    sql: ${TABLE}.checkout_package_id ;;
    group_label: "1. Checkout"
  }

  dimension: surfer_id {
    type: string
    sql: ${TABLE}.surfer_id ;;
    group_label: "1. Checkout"
  }

  dimension: site_name {
    type: string
    sql: ${TABLE}.site_name ;;
    group_label: "1. Checkout"
  }

  dimension: currency {
    type: string
    sql: ${TABLE}.currency ;;
    group_label: "1. Checkout"
  }

  dimension: affiliate_id {
    type: string
    sql: ${TABLE}.affiliate_id ;;
    group_label: "1. Checkout"
  }

  dimension: origin_airport {
    type: string
    sql: ${TABLE}.origin_airport ;;
    group_label: "1. Checkout"
  }

  dimension: destination_airport {
    type: string
    sql: ${TABLE}.destination_airport ;;
    group_label: "1. Checkout"
  }

  dimension: num_adults {
    type: number
    sql: ${TABLE}.num_adults ;;
    group_label: "1. Checkout"
  }

  dimension: num_children {
    type: number
    sql: ${TABLE}.num_children ;;
    group_label: "1. Checkout"
  }

  dimension: num_infants {
    type: number
    sql: ${TABLE}.num_infants ;;
    group_label: "1. Checkout"
  }

  dimension: num_infants_seat {
    type: number
    sql: ${TABLE}.num_infants_seat ;;
    group_label: "1. Checkout"
  }

  dimension: departure_date {
    type: date
    sql: ${TABLE}.departure_date ;;
    group_label: "1. Checkout"
  }

  dimension: return_date {
    type: date
    sql: ${TABLE}.return_date ;;
    group_label: "1. Checkout"
  }

  dimension: flight_class {
    type: string
    sql: ${TABLE}.flight_class ;;
    group_label: "1. Checkout"
  }

  dimension: fare_class {
    type: string
    sql: ${TABLE}.fare_class ;;
    group_label: "1. Checkout"
  }

  dimension: trip_type {
    type: string
    sql: ${TABLE}.trip_type ;;
    group_label: "1. Checkout"
  }

  measure: number_of_checkouts {
    type: count
    group_label: "1. Checkout"
    value_format_name: decimal_0
  }


  # --- Amadeus Upsell ---
  dimension: amadeus_created_at {
    type: date_time
    sql: ${TABLE}.amadeus_created_at ;;
    group_label: "2. Amadeus Upsell"
    hidden: yes
  }

  dimension: amadeus_search_id {
    type: string
    sql: ${TABLE}.amadeus_search_id ;;
    group_label: "2. Amadeus Upsell"
    hidden: yes
  }

  dimension: amadeus_package_id {
    type: string
    sql: ${TABLE}.amadeus_package_id ;;
    group_label: "2. Amadeus Upsell"
    hidden: yes
  }

  dimension: amadeus_error_code {
    type: string
    sql: ${TABLE}.amadeus_error_code ;;
    group_label: "2. Amadeus Upsell"
  }

  dimension: amadeus_error_message {
    type: string
    sql: ${TABLE}.amadeus_error_message ;;
    group_label: "2. Amadeus Upsell"
  }

  dimension: amadeus_offers_returned {
    type: string
    sql: ${TABLE}.amadeus_offers_returned ;;
    group_label: "2. Amadeus Upsell"
  }

  dimension: has_amadeus_call {
    type: yesno
    sql: (
          ${amadeus_package_id} != ''
          AND (
            ${amadeus_error_message} IS NULL
            OR (
              ${amadeus_error_code} IS NOT NULL
              AND ${amadeus_error_message} IS NOT NULL
            )
          )
        ) ;;
    group_label: "2. Amadeus Upsell"
  }

  dimension: amadeus_validating_carriers {
    type: string
    sql: ${TABLE}.amadeus_validating_carriers ;;
    group_label: "2. Amadeus Upsell"
  }

  dimension: amadeus_marketing_carriers {
    type: string
    sql: ${TABLE}.amadeus_marketing_carriers ;;
    group_label: "2. Amadeus Upsell"
  }

  dimension: amadeus_operating_carriers {
    type: string
    sql: ${TABLE}.amadeus_operating_carriers ;;
    group_label: "2. Amadeus Upsell"
  }

  dimension: original_gds_office_id {
    type: string
    sql: ${TABLE}.original_gds_office_id ;;
    group_label: "2. Amadeus Upsell"
  }

  measure: amadeus_calls_coverage {
    type: sum
    sql: CASE
           WHEN ${has_amadeus_call}
           THEN 1 ELSE 0
         END ;;
    group_label: "2. Amadeus Upsell"
    value_format_name: decimal_0
    hidden: yes
  }

  measure: repetitive_checkouts {
    type: sum
    sql: CASE
           WHEN ${amadeus_error_message} = 'upsell_already_called_for_package'
           THEN 1 ELSE 0
         END ;;
    group_label: "2. Amadeus Upsell"
    value_format_name: decimal_0
  }

  measure: upgraded_checkouts {
    type: sum
    sql: CASE
           WHEN ${amadeus_error_message} = 'upsell_already_called_for_upgraded_package'
           THEN 1 ELSE 0
         END ;;
    group_label: "2. Amadeus Upsell"
    value_format_name: decimal_0
    hidden: yes
  }

  measure: amadeus_return_proportion {
    type: sum
    sql: CASE
           WHEN ${amadeus_offers_returned} > 0
           THEN 1 ELSE 0
         END ;;
    group_label: "2. Amadeus Upsell"
    value_format_name: decimal_0
    hidden: yes
  }

  measure: amadeus_filtered_internally {
    type: sum
    sql: CASE
         WHEN ${amadeus_error_code} IS NULL
           AND (
             ${amadeus_error_message} IS NOT NULL
             AND ${amadeus_error_message} != 'upsell_already_called_for_package'
             AND ${amadeus_error_message} != 'upsell_already_called_for_upgraded_package'
           )
         THEN 1 ELSE 0
       END ;;
    group_label: "2. Amadeus Upsell"
    value_format_name: decimal_0
    hidden: yes
  }


  measure: amadeus_errors_codes {
    type: sum
    sql: CASE
           WHEN ${amadeus_error_code} IS NOT NULL
           THEN 1 ELSE 0
         END ;;
    group_label: "2. Amadeus Upsell"
    value_format_name: decimal_0
  }

  measure: amadeus_error_messages {
    type: sum
    sql: CASE
           WHEN ${amadeus_error_message} IS NOT NULL
           THEN 1 ELSE 0
         END ;;
    group_label: "2. Amadeus Upsell"
    value_format_name: decimal_0
  }

  measure: amadeus_calls_coverage_pct {
    type: number
    sql: CASE WHEN ${number_of_checkouts} = 0 THEN NULL ELSE ${amadeus_calls_coverage} * 1.0 / ${number_of_checkouts} END ;;
    group_label: "2. Amadeus Upsell"
    value_format_name: percent_2
  }

  measure: repetitive_checkouts_pct {
    type: number
    sql: CASE WHEN ${number_of_checkouts} = 0 THEN NULL ELSE ${repetitive_checkouts} * 1.0 / ${number_of_checkouts} END ;;
    group_label: "2. Amadeus Upsell"
    value_format_name: percent_2
  }

  measure: upgraded_checkouts_pct {
    type: number
    sql: CASE WHEN ${number_of_checkouts} = 0 THEN NULL ELSE ${upgraded_checkouts} * 1.0 / ${number_of_checkouts} END ;;
    group_label: "2. Amadeus Upsell"
    value_format_name: percent_2
  }

  measure: amadeus_return_proportion_pct {
    type: number
    sql: CASE WHEN ${number_of_checkouts} = 0 THEN NULL ELSE ${amadeus_return_proportion} * 1.0 / ${number_of_checkouts} END ;;
    group_label: "2. Amadeus Upsell"
    value_format_name: percent_2
  }

  measure: amadeus_filtered_internally_pct {
    type: number
    sql: CASE WHEN ${number_of_checkouts} = 0 THEN NULL ELSE ${amadeus_filtered_internally} * 1.0 / ${number_of_checkouts} END ;;
    group_label: "2. Amadeus Upsell"
    value_format_name: percent_2
  }

  measure: amadeus_error_codes_pct {
    type: number
    sql: CASE WHEN ${number_of_checkouts} = 0 THEN NULL ELSE ${amadeus_errors_codes} * 1.0 / ${number_of_checkouts} END ;;
    group_label: "2. Amadeus Upsell"
    value_format_name: percent_2
  }

  measure: amadeus_error_messages_pct {
    type: number
    sql: CASE WHEN ${number_of_checkouts} = 0 THEN NULL ELSE ${amadeus_error_messages} * 1.0 / ${number_of_checkouts} END ;;
    group_label: "2. Amadeus Upsell"
    value_format_name: percent_2
  }


  # --- Routehappy fields  ---
  dimension: routehapp_created_at {
    type: date_time
    sql: ${TABLE}.routehapp_created_at ;;
    group_label: "3. Routehappy"
    hidden: yes
  }

  dimension: routehapp_scope {
    type: string
    sql: ${TABLE}.routehapp_scope ;;
    group_label: "3. Routehappy"
  }

  dimension: routehapp_search_id {
    type: string
    sql: ${TABLE}.routehapp_search_id ;;
    group_label: "3. Routehappy"
    hidden: yes
  }

  dimension: routehapp_package_id {
    type: string
    sql: ${TABLE}.routehapp_package_id ;;
    group_label: "3. Routehappy"
    hidden: yes
  }

  dimension: routehapp_packages_sent {
    type: string
    sql: ${TABLE}.routehapp_packages_sent ;;
    group_label: "3. Routehappy"
  }

  dimension: routehapp_errors_raw {
    type: string
    sql: ${TABLE}.routehapp_errors ;;
    group_label: "3. Routehappy"
  }

  dimension: routehapp_error_mapped {
    type: string
    sql: CASE
         WHEN match(${routehapp_errors_raw}, '^Fare for flight .+ is not matched$')
           THEN 'Fare for flight ### is not matched'
         WHEN match(${routehapp_errors_raw}, '^Segment #[0-9]+ is not matched$')
           THEN 'Segment ### is not matched'
         ELSE ${routehapp_errors_raw}
       END ;;
    group_label: "3. Routehappy"
  }

  dimension: has_routehappy_call {
    type: yesno
    sql: ${routehapp_package_id} IS NOT NULL ;;
    group_label: "3. Routehappy"
  }

  dimension: RH_empty {
    type: yesno
    sql: ${routehapp_errors_raw} IS NOT NULL AND (${final_step_offers_shown} = 0 OR ${final_step_offers_shown} IS NULL) ;;
    group_label: "3. Routehappy"
  }

  dimension: RH_error_not_empty {
    type: yesno
    sql: ${routehapp_errors_raw} IS NOT NULL AND ${final_step_offers_shown} != 0 ;;
    group_label: "3. Routehappy"
  }

  measure: RH_empty_count {
    type: sum
    sql: CASE WHEN ${RH_empty} THEN 1 ELSE 0 END ;;
    group_label: "3. Routehappy"
    value_format_name: decimal_0
  }

  measure: RH_error_not_empty_count {
    type: sum
    sql: CASE WHEN ${RH_error_not_empty} THEN 1 ELSE 0 END ;;
    group_label: "3. Routehappy"
    value_format_name: decimal_0
  }

  measure: RH_empty_pct {
    type: number
    sql: CASE WHEN ${number_of_checkouts} = 0 THEN NULL ELSE ${RH_empty_count} * 1.0 / ${number_of_checkouts} END ;;
    group_label: "3. Routehappy"
    value_format_name: percent_2
  }

  measure: RH_error_not_empty_pct {
    type: number
    sql: CASE WHEN ${number_of_checkouts} = 0 THEN NULL ELSE ${RH_error_not_empty_count} * 1.0 / ${number_of_checkouts} END ;;
    group_label: "3. Routehappy"
    value_format_name: percent_2
  }

  measure: routehappy_errors_count {
    type: sum
    sql: CASE WHEN ${routehapp_error_mapped} IS NOT NULL THEN 1 ELSE 0 END ;;
    group_label: "3. Routehappy"
    value_format_name: decimal_0
  }

  measure: routehappy_calls_count {
    type: sum
    sql: CASE WHEN ${has_routehappy_call} THEN 1 ELSE 0 END ;;
    group_label: "3. Routehappy"
    value_format_name: decimal_0
    hidden: yes
  }

  measure: routehappy_sent_count {
    type: sum
    sql: CASE WHEN ${routehapp_packages_sent} > 0 THEN 1 ELSE 0 END ;;
    group_label: "3. Routehappy"
    value_format_name: decimal_0
    hidden: yes
  }

  measure: routehappy_errors_pct {
    type: number
    sql: CASE WHEN ${number_of_checkouts} = 0 THEN NULL ELSE ${routehappy_errors_count} * 1.0 / ${number_of_checkouts} END ;;
    group_label: "3. Routehappy"
    value_format_name: percent_2
  }

  measure: routehappy_calls_pct {
    type: number
    sql: CASE WHEN ${number_of_checkouts} = 0 THEN NULL ELSE ${routehappy_calls_count} * 1.0 / ${number_of_checkouts} END ;;
    group_label: "3. Routehappy"
    value_format_name: percent_2
  }

  measure: routehappy_sent_pct {
    type: number
    sql: CASE WHEN ${number_of_checkouts} = 0 THEN NULL ELSE ${routehappy_sent_count} * 1.0 / ${number_of_checkouts} END ;;
    group_label: "3. Routehappy"
    value_format_name: percent_2
  }

  # --- Final Step Upsell ---
  dimension: final_step_created_at {
    type: date_time
    sql: ${TABLE}.final_step_created_at ;;
    group_label: "4. Final Step Upsell"
    hidden: yes
  }

  dimension: final_step_search_id {
    type: string
    sql: ${TABLE}.final_step_search_id ;;
    group_label: "4. Final Step Upsell"
    hidden: yes
  }

  dimension: final_step_package_id {
    type: string
    sql: ${TABLE}.final_step_package_id ;;
    group_label: "4. Final Step Upsell"
    hidden: yes
  }

  dimension: is_eligible_for_upgrade {
    type: yesno
    sql: ${TABLE}.is_eligible_for_upgrade ;;
    group_label: "4. Final Step Upsell"
  }

  dimension: final_step_offers_returned {
    type: string
    sql: ${TABLE}.final_step_offers_returned ;;
    group_label: "4. Final Step Upsell"
  }

  dimension: final_step_offers_shown {
    type: string
    sql: ${TABLE}.final_step_offers_shown ;;
    group_label: "4. Final Step Upsell"
  }

  dimension: has_final_step_call {
    type: yesno
    sql: ${final_step_package_id} IS NOT NULL ;;
    group_label: "4. Final Step Upsell"
  }

  measure: final_step_offers_returned_count {
    type: sum
    sql: CASE WHEN ${final_step_offers_returned} > 0 THEN 1 ELSE 0 END ;;
    group_label: "4. Final Step Upsell"
    value_format_name: decimal_0
    hidden: yes
  }

  measure: final_step_offers_shown_count {
    type: sum
    sql: CASE WHEN ${final_step_offers_shown} > 0 THEN 1 ELSE 0 END ;;
    group_label: "4. Final Step Upsell"
    value_format_name: decimal_0
    hidden: yes
  }

  measure: final_step_eligible_count {
    type: sum
    sql: CASE WHEN ${is_eligible_for_upgrade} THEN 1 ELSE 0 END ;;
    group_label: "4. Final Step Upsell"
    value_format_name: decimal_0
    hidden: yes
  }

  measure: final_step_offers_returned_pct {
    type: number
    sql: CASE WHEN ${number_of_checkouts} = 0 THEN NULL ELSE ${final_step_offers_returned_count} * 1.0 / ${number_of_checkouts} END ;;
    group_label: "4. Final Step Upsell"
    value_format_name: percent_2
  }

  measure: final_step_offers_shown_pct {
    type: number
    sql: CASE WHEN ${number_of_checkouts} = 0 THEN NULL ELSE ${final_step_offers_shown_count} * 1.0 / ${number_of_checkouts} END ;;
    group_label: "4. Final Step Upsell"
    value_format_name: percent_2
  }

  measure: final_step_eligible_pct {
    type: number
    sql: CASE WHEN ${number_of_checkouts} = 0 THEN NULL ELSE ${final_step_eligible_count} * 1.0 / ${number_of_checkouts} END ;;
    group_label: "4. Final Step Upsell"
    value_format_name: percent_2
  }


}
