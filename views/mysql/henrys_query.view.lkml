view: henrys_query {
  derived_table: {
  sql:
      SELECT
        DATE(created_date) AS dd,
        COUNT(*) AS checkouts,
        SUM(IF(response_payload->>'$.fare_family_options_short' <> '[[]]', 1, 0)) AS ff,
        SUM(IF(response_payload->>'$.fare_family_options_short' <> '[[]]', 1, 0)) / COUNT(*) AS proportion
      FROM fare_family_options_requests
      WHERE created_date BETWEEN CURDATE() - INTERVAL 30 DAY
      GROUP BY dd
      ;;
  }

  dimension_group: dd {
    type: time
    timeframes: [raw, date, week, month]
    sql: ${TABLE}.dd ;;
  }

  measure: checkouts {
    type: number
    sql: ${TABLE}.checkouts ;;
    value_format_name: decimal_0
    label: "Total Requests"
  }

  measure: ff {
    type: number
    sql: ${TABLE}.ff ;;
    value_format_name: decimal_0
    label: "Non-empty Fare Family Options"
  }

  measure: proportion {
    type: number
    sql: ${TABLE}.proportion ;;
    value_format_name: percent_2
    label: "Proportion with Fare Family Options"
  }
}
