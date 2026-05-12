connection: "clickhouse-prod"

# Only include views that use ClickHouse
include: "/views/clickhouse/*.view.lkml"

datagroup: checkout_with_upsell_daily {
  sql_trigger: SELECT toDate(now()) ;;
  max_cache_age: "24 hours"
}

# Define explores based on ClickHouse views
explore: checkout_with_upsell {
  label: "Checkout with Upsell"
  persist_with: checkout_with_upsell_daily
}
