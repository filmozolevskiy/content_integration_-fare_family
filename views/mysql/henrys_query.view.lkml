view: henrys_query {
  derived_table: {
  sql:
      SELECT
        DATE(created_date) AS dd,
        COUNT(*) AS checkouts,
        SUM(IF(response_payload->>'$.fare_family_options_short' <> '[[]]', 1, 0)) AS ff,
        SUM(IF(response_payload->>'$.fare_family_options_short' <> '[[]]', 1, 0)) / COUNT(*) AS proportion
      FROM fare_family_options_requests
      WHERE created_date >= CURDATE() - INTERVAL 60 DAY
      GROUP BY dd
      ;;
  }

  dimension_group: dd {
    type: time
    timeframes: [raw, date, week, month]
    sql: ${TABLE}.dd ;;
    group_label: "1. Date"
    label: "Request Date"
    description: "Date of the fare family options request."
  }

  measure: checkouts {
    type: number
    sql: ${TABLE}.checkouts ;;
    value_format_name: decimal_0
    label: "Total Requests"
    group_label: "2. Metrics"
    description: "Total number of fare_family_options_requests for the day."
  }

  measure: ff {
    type: number
    sql: ${TABLE}.ff ;;
    value_format_name: decimal_0
    label: "Non-empty Fare Family Options"
    group_label: "2. Metrics"
    description: "Requests where the fare_family_options_short response was non-empty."
  }

  measure: proportion {
    type: number
    sql: ${TABLE}.proportion ;;
    value_format_name: percent_2
    label: "Proportion with Fare Family Options"
    group_label: "2. Metrics"
    description: "Share of requests that returned at least one fare family option."
  }
}
