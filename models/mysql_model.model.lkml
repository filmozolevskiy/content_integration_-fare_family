connection: "ota"

# Only include views that use MySQL
include: "/views/mysql/*.view.lkml"

# Define explores based on MySQL views
explore: upgrade_attempts {
  label: "Upsell Attempts"
}

explore: upgraded_bookings {
  label: "Upsell Bookings"
}

explore: henrys_query {
  label: "Upsell Henry"
}
