view: checkout_with_upsell {
  derived_table: {
    sql:
      WITH
        total_checkouts AS (
          SELECT
            begin_checkout_timestamp,
            search_id,
            package_id,
            ROW_NUMBER() OVER (PARTITION BY search_id, package_id ORDER BY begin_checkout_timestamp DESC) AS rn
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
            ROW_NUMBER() OVER (PARTITION BY search_id, package_id, error_code, error_message, offers_returned ORDER BY created_at DESC) AS rn
          FROM jupiter.jupiter_fare_priceupsellwithoutpnr
        ),
        routehappy AS (
          SELECT
            created_at,
            search_id,
            package_id,
            itineraries,
            error_message,
            ROW_NUMBER() OVER (PARTITION BY search_id, package_id, itineraries, error_message ORDER BY created_at DESC) AS rn
          FROM jupiter.jupiter_consolidated
        )

      SELECT
      total_checkouts.begin_checkout_timestamp AS checkout_begin_checkout_timestamp,
      total_checkouts.search_id AS checkout_search_id,
      total_checkouts.package_id AS checkout_package_id,

      amadeus_upsell.created_at AS amadeus_created_at,
      NULLIF(amadeus_upsell.search_id, '') AS amadeus_search_id,
      NULLIF(amadeus_upsell.package_id, '') AS amadeus_package_id,
      amadeus_upsell.error_code AS amadeus_error_code,
      amadeus_upsell.error_message AS amadeus_error_message,
      amadeus_upsell.offers_returned AS amadeus_offers_returned,

      routehappy.created_at AS routehapp_created_at,
      routehappy.search_id AS routehapp_search_id,
      routehappy.package_id AS routehapp_package_id,
      routehappy.itineraries AS routehapp_packages_sent,
      routehappy.error_message AS routehapp_errors

      FROM total_checkouts
      LEFT JOIN amadeus_upsell
      ON total_checkouts.search_id = amadeus_upsell.search_id
      AND total_checkouts.package_id = amadeus_upsell.package_id
      LEFT JOIN routehappy
      ON total_checkouts.search_id = routehappy.search_id
      AND total_checkouts.package_id = routehappy.package_id

      WHERE total_checkouts.rn = 1
      AND (amadeus_upsell.rn = 1 OR amadeus_upsell.rn = 0)
      AND (routehappy.rn = 1 OR routehappy.rn = 0)
      AND total_checkouts.begin_checkout_timestamp >= subtractDays(today(), 1)
      ;;
  }

  # Dimensions

  dimension: checkout_begin_checkout_timestamp {
    type: date_time
    sql: ${TABLE}.checkout_begin_checkout_timestamp ;;
  }

  dimension: checkout_search_id {
    primary_key: yes
    type: string
    sql: ${TABLE}.checkout_search_id ;;
  }

  dimension: checkout_package_id {
    type: string
    sql: ${TABLE}.checkout_package_id ;;
  }

  dimension: amadeus_created_at {
    type: date_time
    sql: ${TABLE}.amadeus_created_at ;;
  }

  dimension: amadeus_search_id {
    type: string
    sql: ${TABLE}.amadeus_search_id ;;
  }

  dimension: amadeus_package_id {
    type: string
    sql: ${TABLE}.amadeus_package_id ;;
  }

  dimension: amadeus_error_code {
    type: string
    sql: ${TABLE}.amadeus_error_code ;;
  }

  dimension: amadeus_error_message {
    type: string
    sql: ${TABLE}.amadeus_error_message ;;
  }

  dimension: amadeus_offers_returned {
    type: string
    sql: ${TABLE}.amadeus_offers_returned ;;
  }

  dimension: has_amadeus_call {
    type: yesno
    sql: ${amadeus_package_id} IS NOT NULL ;;
  }

  dimension: routehapp_created_at {
    type: date_time
    sql: ${TABLE}.routehapp_created_at ;;
  }

  dimension: routehapp_search_id {
    type: string
    sql: ${TABLE}.routehapp_search_id ;;
  }

  dimension: routehapp_package_id {
    type: string
    sql: ${TABLE}.routehapp_package_id ;;
  }

  dimension: routehapp_packages_sent {
    type: string
    sql: ${TABLE}.routehapp_packages_sent ;;
  }

  dimension: routehapp_errors {
    type: string
    sql: ${TABLE}.routehapp_errors ;;
  }

}
