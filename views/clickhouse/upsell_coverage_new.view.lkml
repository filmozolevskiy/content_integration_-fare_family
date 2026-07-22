view: upsell_coverage_new {
  sql_table_name: upsells.fare_family_upgrade_options_event ;;
  # derived_table: {
  #   sql:
  #         SELECT
  #           date(timestamp) as date,
  #           event_id,
  #           event_key,
  #           search_id,
  #           base_package_id,
  #           current_package_id,
  #           checkout_id,
  #           is_multiticket,
  #           affiliate_id,
  #           currency,
  #           site_id,
  #           device_type,
  #           is_upgraded_package,
  #           context,
  #           is_eligible
  #           ineligibility_reason,
  #           is_cached,
  #           master_upgrade_source,
  #           gds_no_options_reason,
  #           master_fare_family_names,
  #           has_atpco_features,
  #           atpco_error,

  #         FROM upsells.fare_family_upgrade_options_event

# ------------------------------------------------------------------
# Identifiers
# ------------------------------------------------------------------

dimension: event_id {
  primary_key: yes
  type: string
  sql: ${TABLE}.event_id ;;
}

dimension: event_key {
  type: string
  sql: ${TABLE}.event_key ;;
}

dimension: search_id {
  type: string
  sql: ${TABLE}.search_id ;;
}

dimension: base_package_id {
  type: string
  sql: ${TABLE}.base_package_id ;;
}

dimension: current_package_id {
  type: string
  sql: ${TABLE}.current_package_id ;;
}

dimension: checkout_id {
  type: string
  sql: ${TABLE}.checkout_id ;;
}

# ------------------------------------------------------------------
# Core flags / attributes
# ------------------------------------------------------------------

dimension: is_multiticket {
  type: yesno
  sql: ${TABLE}.is_multiticket ;;
}

dimension: affiliate_id {
  type: number
  sql: ${TABLE}.affiliate_id ;;
}

dimension: currency {
  type: string
  sql: ${TABLE}.currency ;;
}

dimension: site_id {
  type: number
  sql: ${TABLE}.site_id ;;
}

dimension: device_type {
  type: string
  sql: ${TABLE}.device_type ;;
}

dimension: is_upgraded_package {
  type: yesno
  sql: ${TABLE}.is_upgraded_package ;;
}

dimension: context {
  type: string
  sql: ${TABLE}.context ;;
}

dimension: is_eligible {
  type: yesno
  sql: ${TABLE}.is_eligible ;;
}

dimension: ineligibility_reason {
  type: string
  sql: ${TABLE}.ineligibility_reason ;;
}

dimension: is_cached {
  type: yesno
  sql: ${TABLE}.is_cached ;;
}

dimension: trip_type {
  type: string
  sql: ${TABLE}.trip_type ;;
}

# ------------------------------------------------------------------
# Timestamps
# ------------------------------------------------------------------

dimension_group: timestamp {
  type: time
  timeframes: [
    raw,
    time,
    hour,
    date,
    week,
    month,
    quarter,
    year
  ]
  sql: ${TABLE}.timestamp ;;
}

dimension_group: timestamp_micro {
  type: time
  timeframes: [
    raw,
    time,
    hour,
    date,
    week,
    month
  ]
  sql: ${TABLE}.timestamp_micro ;;
}

# ------------------------------------------------------------------
# Upgrade source / GDS related
# ------------------------------------------------------------------

dimension: master_upgrade_source {
  type: string
  sql: ${TABLE}.master_upgrade_source ;;
}

dimension: slave_upgrade_source {
  type: string
  sql: ${TABLE}.slave_upgrade_source ;;
}

dimension: gds_no_options_reason {
  type: string
  sql: ${TABLE}.gds_no_options_reason ;;
}

dimension: master_gds_upsell_count {
  type: number
  sql: ${TABLE}.master_gds_upsell_count ;;
}

dimension: slave_gds_upsell_count {
  type: number
  sql: ${TABLE}.slave_gds_upsell_count ;;
}

dimension: master_fare_family_names {
  type: string
  sql: ${TABLE}.master_fare_family_names ;;
}

dimension: slave_fare_family_names {
  type: string
  sql: ${TABLE}.slave_fare_family_names ;;
}

dimension: has_atpco_features {
  type: yesno
  sql: ${TABLE}.has_atpco_features ;;
}

dimension: atpco_error {
  type: string
  sql: ${TABLE}.atpco_error ;;
}

# ------------------------------------------------------------------
# Filtered counts
# ------------------------------------------------------------------

dimension: master_filtered_empty_count {
  type: number
  sql: ${TABLE}.master_filtered_empty_count ;;
}

dimension: slave_filtered_empty_count {
  type: number
  sql: ${TABLE}.slave_filtered_empty_count ;;
}

dimension: master_filtered_cheaper_count {
  type: number
  sql: ${TABLE}.master_filtered_cheaper_count ;;
}

dimension: slave_filtered_cheaper_count {
  type: number
  sql: ${TABLE}.slave_filtered_cheaper_count ;;
}

dimension: master_filtered_lesser_count {
  type: number
  sql: ${TABLE}.master_filtered_lesser_count ;;
}

dimension: slave_filtered_lesser_count {
  type: number
  sql: ${TABLE}.slave_filtered_lesser_count ;;
}

dimension: master_filtered_multiticket_count {
  type: number
  sql: ${TABLE}.master_filtered_multiticket_count ;;
}

dimension: slave_filtered_multiticket_count {
  type: number
  sql: ${TABLE}.slave_filtered_multiticket_count ;;
}

dimension: master_filtered_price_cap_count {
  type: number
  sql: ${TABLE}.master_filtered_price_cap_count ;;
}

dimension: slave_filtered_price_cap_count {
  type: number
  sql: ${TABLE}.slave_filtered_price_cap_count ;;
}

dimension: master_options_displayed_count {
  type: number
  sql: ${TABLE}.master_options_displayed_count ;;
}

dimension: slave_options_displayed_count {
  type: number
  sql: ${TABLE}.slave_options_displayed_count ;;
}

dimension: master_displayed_fare_family_names {
  type: string
  sql: ${TABLE}.master_displayed_fare_family_names ;;
}

dimension: slave_displayed_fare_family_names {
  type: string
  sql: ${TABLE}.slave_displayed_fare_family_names ;;
}

dimension: no_options_reason {
  type: string
  sql: ${TABLE}.no_options_reason ;;
}

# ------------------------------------------------------------------
# Passenger counts
# ------------------------------------------------------------------

dimension: adt_pax_count {
  type: number
  sql: ${TABLE}.adt_pax_count ;;
}

dimension: chd_pax_count {
  type: number
  sql: ${TABLE}.chd_pax_count ;;
}

dimension: ins_pax_count {
  type: number
  sql: ${TABLE}.ins_pax_count ;;
}

dimension: inl_pax_count {
  type: number
  sql: ${TABLE}.inl_pax_count ;;
}

dimension: total_pax_count {
  type: number
  sql: ${TABLE}.adt_pax_count + ${TABLE}.chd_pax_count + ${TABLE}.ins_pax_count + ${TABLE}.inl_pax_count ;;
}

# ------------------------------------------------------------------
# Carriers / GDS routing
# ------------------------------------------------------------------

dimension: master_marketing_carriers {
  type: string
  sql: ${TABLE}.master_marketing_carriers ;;
}

dimension: slave_marketing_carriers {
  type: string
  sql: ${TABLE}.slave_marketing_carriers ;;
}

dimension: master_operating_carriers {
  type: string
  sql: ${TABLE}.master_operating_carriers ;;
}

dimension: slave_operating_carriers {
  type: string
  sql: ${TABLE}.slave_operating_carriers ;;
}

dimension: master_validating_carrier {
  type: string
  sql: ${TABLE}.master_validating_carrier ;;
}

dimension: slave_validating_carrier {
  type: string
  sql: ${TABLE}.slave_validating_carrier ;;
}

dimension: original_master_gds {
  type: string
  sql: ${TABLE}.original_master_gds ;;
}

dimension: original_slave_gds {
  type: string
  sql: ${TABLE}.original_slave_gds ;;
}

dimension: current_master_gds {
  type: string
  sql: ${TABLE}.current_master_gds ;;
}

dimension: current_slave_gds {
  type: string
  sql: ${TABLE}.current_slave_gds ;;
}

dimension: original_master_office_id {
  type: string
  sql: ${TABLE}.original_master_office_id ;;
}

dimension: original_slave_office_id {
  type: string
  sql: ${TABLE}.original_slave_office_id ;;
}

dimension: current_master_office_id {
  type: string
  sql: ${TABLE}.current_master_office_id ;;
}

dimension: current_slave_office_id {
  type: string
  sql: ${TABLE}.current_slave_office_id ;;
}

dimension: original_master_target_id {
  type: number
  sql: ${TABLE}.original_master_target_id ;;
}

dimension: original_slave_target_id {
  type: number
  sql: ${TABLE}.original_slave_target_id ;;
}

dimension: current_master_target_id {
  type: number
  sql: ${TABLE}.current_master_target_id ;;
}

dimension: current_slave_target_id {
  type: number
  sql: ${TABLE}.current_slave_target_id ;;
}

# ------------------------------------------------------------------
# Measures
# ------------------------------------------------------------------

measure: count {
  type: count
  drill_fields: [event_id, search_id, base_package_id, device_type, timestamp_time]
}

measure: eligible_count {
  type: count
  filters: [is_eligible: "yes"]
}

measure: upgraded_count {
  type: count
  filters: [is_upgraded_package: "yes"]
}

measure: upgrade_rate {
  type: number
  sql: 1.0 * ${upgraded_count} / NULLIF(${eligible_count}, 0) ;;
  value_format_name: percent_2
}

measure: average_master_gds_upsell_count {
  type: average
  sql: ${master_gds_upsell_count} ;;
  value_format_name: decimal_1
}

measure: average_slave_gds_upsell_count {
  type: average
  sql: ${slave_gds_upsell_count} ;;
  value_format_name: decimal_1
}
}
