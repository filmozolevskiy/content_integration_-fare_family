connection: "clickhouse-prod"

# include all the views
include: "/views/**/*.view.lkml"



explore: checkout_with_upsell {

  sql_always_where: ${checkout_with_upsell.checkout_begin_checkout_timestamp} >= DATE_SUB(CURRENT_DATE(), INTERVAL 1 WEEK) ;;

}
