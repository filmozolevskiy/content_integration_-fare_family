view: fare_family_checkout_legs {
  # One row per ticket (leg) of a checkout: Master always, Slave only for
  # multi-ticket. Joined to fare_family_checkouts with a ClickHouse ARRAY JOIN
  # (see the model); the tuple is built there from fare_family_checkouts fields:
  # 1 leg, 2 validating carrier, 3 content source, 4 office, 5 upgrade source GDS,
  # 6 options displayed, 7 options returned.
  # Why (2026-09-29, FM): checkout coverage counts a multi-ticket checkout when
  # either leg displayed options, but the carrier / GDS fields are per leg. By
  # master carrier, F8 showed 16.37% coverage (2026-09-22 to 09-28 NY) that was
  # all from the WS / AC / PD slave leg; F8 legs are 0.00% (32,613 legs).
  # 13.6% of checkouts are multi-ticket.

  dimension: checkout_leg_id {
    primary_key: yes
    hidden: yes
    type: string
    sql: concat(${fare_family_checkouts.checkout_id}, '-', ${TABLE}.1) ;;
  }

  dimension: leg {
    type: string
    sql: ${TABLE}.1 ;;
    label: "Leg"
    description: "Ticket of the checkout: Master, or Slave (second ticket of a multi-ticket checkout)."
  }

  dimension: leg_validating_carrier {
    type: string
    sql: ${TABLE}.2 ;;
    label: "Leg Validating Carrier"
    description: "Validating carrier of this leg. Use it with the Checkout Legs measures for coverage by carrier."
  }

  dimension: leg_fare_provider {
    type: string
    sql: ${TABLE}.3 ;;
    label: "Leg Fare Provider"
    description: "Content source (GDS) of this leg's base package. Use it with the Checkout Legs measures for coverage by content source."
  }

  dimension: leg_office_id {
    type: string
    sql: ${TABLE}.4 ;;
    label: "Leg Office ID"
    description: "Office id of this leg's base package."
  }

  dimension: leg_upgrade_source_gds {
    type: string
    sql: ${TABLE}.5 ;;
    label: "Leg Upgrade Source GDS"
    description: "Content source of the office(s) used for this leg's upsell call. Same mapping as Master / Slave Upgrade Source GDS."
  }

  dimension: leg_has_options_displayed {
    type: yesno
    sql: ${TABLE}.6 ;;
    label: "Leg Has Options Available"
    description: "Yes when more than 1 fare family was displayed for this leg on any event of the checkout. A count of 1 is the original fare only."
  }

  dimension: leg_has_gds_options {
    type: yesno
    sql: ${TABLE}.7 ;;
    label: "Leg Has Options Returned"
    description: "Yes when the content source returned upsell options for this leg on any event of the checkout."
  }

  measure: checkout_legs_nbr {
    type: count
    label: "Checkout Legs #"
    description: "Number of checkout legs: 1 per single-ticket checkout, 2 per multi-ticket checkout."
  }

  measure: checkout_legs_with_options_nbr {
    type: count
    filters: [leg_has_options_displayed: "yes"]
    label: "Checkout Legs with Options Available #"
    description: "Checkout legs where the customer could choose an upgrade for this leg."
  }

  measure: checkout_legs_with_options_pct {
    type: number
    sql: 1.0 * ${checkout_legs_with_options_nbr} / NULLIF(${checkout_legs_nbr}, 0) ;;
    value_format_name: percent_2
    label: "Checkout Legs with Options Available %"
    description: "Checkout Legs with Options Available # / Checkout Legs #. Coverage by carrier or content source: each leg is counted only for its own options."
  }

  measure: checkout_legs_with_options_returned_nbr {
    type: count
    filters: [leg_has_gds_options: "yes"]
    label: "Checkout Legs with Options Returned #"
    description: "Checkout legs where the content source returned upsell options for this leg (before display filtering)."
  }

  measure: checkout_legs_with_options_returned_pct {
    type: number
    sql: 1.0 * ${checkout_legs_with_options_returned_nbr} / NULLIF(${checkout_legs_nbr}, 0) ;;
    value_format_name: percent_2
    label: "Checkout Legs with Options Returned %"
    description: "Checkout Legs with Options Returned # / Checkout Legs #."
  }
}
