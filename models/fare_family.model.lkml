connection: "clickhouse-prod"
connection: "ota"

# include all the views
include: "/views/**/*.view.lkml"



explore: checkout_with_upsell { }
explore: upgrade_attempts { }
