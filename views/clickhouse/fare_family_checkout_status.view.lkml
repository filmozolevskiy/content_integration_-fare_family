view: fare_family_checkout_status {
  # One row per checkout_id: one upsell status per checkout (Trello #3121).
  # Why (2026-09-25, FM): priority rule (Upgraded > Fresh > Ineligible > Repetitive).
  # Customers upgrade after their first checkout event (464 fresh-then-upgraded
  # checkouts on 2026-09-22 NY), so a first-event rule misses ~590 upgrades/day.
  # Ineligible never mixes with another reason (0 checkouts).
  # Ephemeral SQL derived table — no datagroup_trigger (clickhouse-prod rejects PDTs).
  # The date condition reuses the explore's timestamp_date filter; set by
  # conditionally_filter (30 days) when the user adds none.
  derived_table: {
    sql: SELECT checkout_id,
                multiIf(countIf(ineligibility_reason = 'upsell_already_called_for_upgraded_package') > 0, 'Upgraded',
                        countIf(ineligibility_reason IS NULL) > 0, 'Fresh',
                        countIf(ineligibility_reason LIKE 'ineligible_for_%') > 0, 'Ineligible',
                        countIf(ineligibility_reason = 'upsell_already_called_for_package') > 0, 'Repetitive',
                        'Other') AS checkout_upsell_status
         FROM upsells.fare_family_upgrade_options_event
         WHERE context = 'checkout'
           AND checkout_id NOT IN ('', 'undefined') AND checkout_id IS NOT NULL
           AND {% condition fare_family_events.timestamp_date %} timestamp {% endcondition %}
         GROUP BY checkout_id ;;
  }

  dimension: checkout_id {
    primary_key: yes
    hidden: yes
    type: string
    sql: ${TABLE}.checkout_id ;;
  }

  dimension: checkout_upsell_status {
    type: string
    sql: ${TABLE}.checkout_upsell_status ;;
    group_label: "04. Eligibility"
    label: "Checkout Upsell Status"
    description: "One status per checkout. Upgraded = upgraded during checkout; Fresh = upsell called at checkout; Ineligible = ineligible_for_*; Repetitive = cached re-render only. Priority in that order. Statuses do not overlap and add up to 100%. Use with Checkout #."
    suggestions: ["Upgraded", "Fresh", "Ineligible", "Repetitive"]
  }
}
