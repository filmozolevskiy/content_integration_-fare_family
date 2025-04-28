connection: "clickhouse-prod"

# include all the views
include: "/views/**/*.view.lkml"


datagroup: fara_family_default_datagroup {
  # sql_trigger: SELECT MAX(id) FROM etl_log;;
  max_cache_age: "1 hour"
}

explore: checkout_with_upsell {

  sql_always_where: ${checkout_with_upsell.begin_checkout_timestamp} >= DATE_SUB(CURRENT_DATE(), INTERVAL 1 WEAK) ;;

}
