connection: "ota"

# Only include views that use MySQL
include: "/views/mysql/*.view.lkml"

datagroup: upgrade_attempts_daily {
  sql_trigger: SELECT CURDATE() ;;
  max_cache_age: "24 hours"
}

datagroup: upgraded_bookings_daily {
  sql_trigger: SELECT CURDATE() ;;
  max_cache_age: "24 hours"
}

datagroup: henrys_query_daily {
  sql_trigger: SELECT CURDATE() ;;
  max_cache_age: "24 hours"
}

# Define explores based on MySQL views
explore: upgrade_attempts {
  label: "Upsell Attempts"
  persist_with: upgrade_attempts_daily

  join: daily_bookings_total {
    type: left_outer
    relationship: many_to_one
    sql_on: ${upgrade_attempts.date_created_date} = ${daily_bookings_total.booking_date} ;;
  }
}

explore: upgraded_bookings {
  label: "Upsell Bookings"
  persist_with: upgraded_bookings_daily
}

explore: henrys_query {
  label: "Upsell Henry"
  persist_with: henrys_query_daily
}
