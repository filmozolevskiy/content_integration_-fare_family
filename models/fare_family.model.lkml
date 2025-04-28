connection: "clickhouse-prod"

# include all the views
include: "/views/**/*.view.lkml"



explore: checkout_with_upsell { }
