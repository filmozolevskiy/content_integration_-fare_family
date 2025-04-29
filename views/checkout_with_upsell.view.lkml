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
            ROW_NUMBER() OVER (
              PARTITION BY
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
                trip_type
              ORDER BY begin_checkout_timestamp DESC
            ) AS rn
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
      ROW_NUMBER() OVER (
      PARTITION BY search_id, package_id, error_code, error_message, offers_returned
      ORDER BY created_at DESC
      ) AS rn
      FROM jupiter.jupiter_fare_priceupsellwithoutpnr
      ),

      routehappy AS (
      SELECT
      created_at,
      search_id,
      package_id,
      itineraries,
      error_message,
      ROW_NUMBER() OVER (
      PARTITION BY search_id, package_id, itineraries, error_message
      ORDER BY created_at DESC
      ) AS rn
      FROM jupiter.jupiter_consolidated
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
      PARTITION BY search_id, package_id, is_eligible_for_upgrade, offers_returned, offers_shown
      ORDER BY created_at DESC
      ) AS rn
      FROM jupiter.jupiter_upsell_proposals
      )

      SELECT
      total_checkouts.begin_checkout_timestamp AS checkout_begin_checkout_timestamp,
      total_checkouts.search_id AS checkout_search_id,
      total_checkouts.package_id AS checkout_package_id,
      total_checkouts.surfer_id,
      total_checkouts.site_name,
      total_checkouts.currency,
      total_checkouts.affiliate_id,
      total_checkouts.origin_airport,
      total_checkouts.destination_airport,
      total_checkouts.num_adults,
      total_checkouts.num_children,
      total_checkouts.num_infants,
      total_checkouts.num_infants_seat,
      total_checkouts.departure_date,
      total_checkouts.return_date,
      total_checkouts.flight_class,
      total_checkouts.fare_class,
      total_checkouts.trip_type,

      amadeus_upsell.created_at AS amadeus_created_at,
      NULLIF(amadeus_upsell.search_id, '') AS amadeus_search_id,
      NULLIF(amadeus_upsell.package_id, '') AS amadeus_package_id,
      amadeus_upsell.error_code AS amadeus_error_code,
      amadeus_upsell.error_message AS amadeus_error_message,
      amadeus_upsell.offers_returned AS amadeus_offers_returned,

      routehappy.created_at AS routehapp_created_at,
      NULLIF(routehappy.search_id, '') AS routehapp_search_id,
      NULLIF(routehappy.package_id, '') AS routehapp_package_id,
      routehappy.itineraries AS routehapp_packages_sent,
      routehappy.error_message AS routehapp_errors,

      final_step.created_at AS final_step_created_at,
      NULLIF(final_step.search_id, '') AS final_step_search_id,
      NULLIF(final_step.package_id, '') AS final_step_package_id,
      final_step.is_eligible_for_upgrade,
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
      AND total_checkouts.begin_checkout_timestamp >= subtractDays(today(), 1)
      ;;
  }

  # 🎯 Dimensions organized by source table (group_label)

  # --- Checkout ---
  dimension: checkout_begin_checkout_timestamp {
    type: date_time
    sql: ${TABLE}.checkout_begin_checkout_timestamp ;;
    group_label: "Checkout"
  }

  dimension: checkout_search_id {
    primary_key: yes
    type: string
    sql: ${TABLE}.checkout_search_id ;;
    group_label: "Checkout"
  }

  dimension: checkout_package_id {
    type: string
    sql: ${TABLE}.checkout_package_id ;;
    group_label: "Checkout"
  }

  dimension: surfer_id {
    type: string
    sql: ${TABLE}.surfer_id ;;
    group_label: "Checkout"
  }

  dimension: site_name {
    type: string
    sql: ${TABLE}.site_name ;;
    group_label: "Checkout"
  }

  dimension: currency {
    type: string
    sql: ${TABLE}.currency ;;
    group_label: "Checkout"
  }

  dimension: affiliate_id {
    type: string
    sql: ${TABLE}.affiliate_id ;;
    group_label: "Checkout"
  }

  dimension: origin_airport {
    type: string
    sql: ${TABLE}.origin_airport ;;
    group_label: "Checkout"
  }

  dimension: destination_airport {
    type: string
    sql: ${TABLE}.destination_airport ;;
    group_label: "Checkout"
  }

  dimension: num_adults {
    type: number
    sql: ${TABLE}.num_adults ;;
    group_label: "Checkout"
  }

  dimension: num_children {
    type: number
    sql: ${TABLE}.num_children ;;
    group_label: "Checkout"
  }

  dimension: num_infants {
    type: number
    sql: ${TABLE}.num_infants ;;
    group_label: "Checkout"
  }

  dimension: num_infants_seat {
    type: number
    sql: ${TABLE}.num_infants_seat ;;
    group_label: "Checkout"
  }

  dimension: departure_date {
    type: date
    sql: ${TABLE}.departure_date ;;
    group_label: "Checkout"
  }

  dimension: return_date {
    type: date
    sql: ${TABLE}.return_date ;;
    group_label: "Checkout"
  }

  dimension: flight_class {
    type: string
    sql: ${TABLE}.flight_class ;;
    group_label: "Checkout"
  }

  dimension: fare_class {
    type: string
    sql: ${TABLE}.fare_class ;;
    group_label: "Checkout"
  }

  dimension: trip_type {
    type: string
    sql: ${TABLE}.trip_type ;;
    group_label: "Checkout"
  }

  # --- Amadeus Upsell ---
  dimension: amadeus_created_at {
    type: date_time
    sql: ${TABLE}.amadeus_created_at ;;
    group_label: "Amadeus Upsell"
  }

  dimension: amadeus_search_id {
    type: string
    sql: ${TABLE}.amadeus_search_id ;;
    group_label: "Amadeus Upsell"
  }

  dimension: amadeus_package_id {
    type: string
    sql: ${TABLE}.amadeus_package_id ;;
    group_label: "Amadeus Upsell"
  }

  dimension: amadeus_error_code {
    type: string
    sql: ${TABLE}.amadeus_error_code ;;
    group_label: "Amadeus Upsell"
  }

  dimension: amadeus_error_message {
    type: string
    sql: ${TABLE}.amadeus_error_message ;;
    group_label: "Amadeus Upsell"
  }

  dimension: amadeus_offers_returned {
    type: string
    sql: ${TABLE}.amadeus_offers_returned ;;
    group_label: "Amadeus Upsell"
  }

  dimension: has_amadeus_call {
    type: yesno
    sql: ${amadeus_package_id} IS NOT NULL ;;
    group_label: "Amadeus Upsell"
  }

  # --- Routehappy ---
  dimension: routehapp_created_at {
    type: date_time
    sql: ${TABLE}.routehapp_created_at ;;
    group_label: "Routehappy"
  }

  dimension: routehapp_search_id {
    type: string
    sql: ${TABLE}.routehapp_search_id ;;
    group_label: "Routehappy"
  }

  dimension: routehapp_package_id {
    type: string
    sql: ${TABLE}.routehapp_package_id ;;
    group_label: "Routehappy"
  }

  dimension: routehapp_packages_sent {
    type: string
    sql: ${TABLE}.routehapp_packages_sent ;;
    group_label: "Routehappy"
  }

  dimension: routehapp_errors {
    type: string
    sql: ${TABLE}.routehapp_errors ;;
    group_label: "Routehappy"
  }

  dimension: has_routehappy_call {
    type: yesno
    sql: ${routehapp_package_id} IS NOT NULL ;;
    group_label: "Routehappy"
  }

  # --- Final Step Upsell ---
  dimension: final_step_created_at {
    type: date_time
    sql: ${TABLE}.final_step_created_at ;;
    group_label: "Final Step Upsell"
  }

  dimension: final_step_search_id {
    type: string
    sql: ${TABLE}.final_step_search_id ;;
    group_label: "Final Step Upsell"
  }

  dimension: final_step_package_id {
    type: string
    sql: ${TABLE}.final_step_package_id ;;
    group_label: "Final Step Upsell"
  }

  dimension: is_eligible_for_upgrade {
    type: yesno
    sql: ${TABLE}.is_eligible_for_upgrade ;;
    group_label: "Final Step Upsell"
  }

  dimension: final_step_offers_returned {
    type: string
    sql: ${TABLE}.final_step_offers_returned ;;
    group_label: "Final Step Upsell"
  }

  dimension: final_step_offers_shown {
    type: string
    sql: ${TABLE}.final_step_offers_shown ;;
    group_label: "Final Step Upsell"
  }

  dimension: has_final_step_call {
    type: yesno
    sql: ${final_step_package_id} IS NOT NULL ;;
    group_label: "Final Step Upsell"
  }
}
