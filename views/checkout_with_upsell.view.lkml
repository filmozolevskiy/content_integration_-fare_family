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
        WHERE begin_checkout_timestamp >= subtractDays(today(), 30)
      )

      SELECT
      total_checkouts.begin_checkout_timestamp AS checkout_begin_checkout_timestamp,
      total_checkouts.search_id AS checkout_search_id,
      total_checkouts.package_id AS checkout_package_id,
      NULLIF(amadeus_upsell.search_id, '') AS amadeus_search_id,
      NULLIF(amadeus_upsell.package_id, '') AS amadeus_package_id,
      amadeus_upsell.created_at AS amadeus_created_at,
      amadeus_upsell.error_code AS amadeus_error_code,
      amadeus_upsell.error_message AS amadeus_error_message,
      amadeus_upsell.offers_returned AS amadeus_offers_returned
      FROM total_checkouts
      LEFT JOIN (
      SELECT
      created_at,
      search_id,
      package_id,
      error_code,
      error_message,
      offers_returned,
      ROW_NUMBER() OVER (PARTITION BY search_id, package_id, error_code, error_message, offers_returned ORDER BY created_at DESC) AS rn
      FROM jupiter.jupiter_fare_priceupsellwithoutpnr
      ) AS amadeus_upsell
      ON total_checkouts.search_id = amadeus_upsell.search_id
      AND total_checkouts.package_id = amadeus_upsell.package_id
      AND amadeus_upsell.rn = 1
      WHERE total_checkouts.rn = 1
      ;;
  }




  # Now define your dimensions based on the new names:

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

}
