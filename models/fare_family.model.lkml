connection: "clickhouse-prod"

# Only include views that use ClickHouse
include: "/views/clickhouse/*.view.lkml"

# Define explores based on ClickHouse views
explore: checkout_with_upsell {
  label: "Upsell"
}
