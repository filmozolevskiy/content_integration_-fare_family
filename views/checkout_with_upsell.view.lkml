view: checkout_with_upsell {
  derived_table: {
    sql:
      WITH total_checkouts AS (
        SELECT
          begin_checkout_timestamp,
          search_id,
          package_id,
          ROW_NUMBER() OVER (PARTITION BY search_id, package_id ORDER BY begin_checkout_timestamp DESC) AS rn
        FROM gtm_views.begin_checkout
        WHERE begin_checkout_timestamp BETWEEN {% condition begin_checkout_timestamp %} {% endcondition %}
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
        WHERE created_at BETWEEN {% condition created_at %} {% endcondition %}
      )

      SELECT
      total_checkouts.begin_checkout_timestamp,
      total_checkouts.search_id,
      total_checkouts.package_id,
      amadeus_upsell.created_at,
      amadeus_upsell.error_code,
      amadeus_upsell.error_message,
      amadeus_upsell.offers_returned
      FROM total_checkouts
      LEFT JOIN amadeus_upsell
      ON total_checkouts.search_id = amadeus_upsell.search_id
      AND total_checkouts.package_id = amadeus_upsell.package_id
      WHERE total_checkouts.rn = 1
      AND (amadeus_upsell.rn = 1 OR amadeus_upsell.rn IS NULL)
      ORDER BY total_checkouts.search_id, total_checkouts.package_id
      ;;
  }

  dimension: begin_checkout_timestamp {
    type: date_time
    sql: ${TABLE}.begin_checkout_timestamp ;;
  }

  dimension: search_id {
    type: string
    primary_key: yes
    sql: ${TABLE}.search_id ;;
  }

  dimension: package_id {
    type: string
    sql: ${TABLE}.package_id ;;
  }

  dimension: created_at {
    type: date_time
    sql: ${TABLE}.created_at ;;
  }

  dimension: error_code {
    type: string
    sql: ${TABLE}.error_code ;;
  }

  dimension: error_message {
    type: string
    sql: ${TABLE}.error_message ;;
  }

  dimension: offers_returned {
    type: string
    sql: ${TABLE}.offers_returned ;;
  }
}
