SELECT
    rcs."creative_page_url"                                                     AS "page_url",
    rs.value:"first_shown"::DATE                                                AS "first_shown",
    rs.value:"last_shown"::DATE                                                 AS "last_shown",
    d.value:"removal_reason"::STRING                                            AS "removal_reason",
    d.value:"violation_category"::STRING                                        AS "violation_category",
    rs.value:"times_shown_lower_bound"::NUMBER                                  AS "times_shown_lower",
    rs.value:"times_shown_upper_bound"::NUMBER                                  AS "times_shown_upper"
FROM "GOOGLE_ADS"."GOOGLE_ADS_TRANSPARENCY_CENTER"."REMOVED_CREATIVE_STATS" rcs,
     LATERAL FLATTEN(input => rcs."region_stats")  rs,
     LATERAL FLATTEN(input => rcs."disapproval")   d
WHERE rs.value:"region_code"::STRING = 'HR'
  AND rs.value:"times_shown_availability_date" IS NULL
  AND rs.value:"times_shown_lower_bound"::NUMBER > 10000
  AND rs.value:"times_shown_upper_bound"::NUMBER < 25000
  AND (
        rcs."audience_selection_approach_info":"contextual_signals"::STRING  <> 'CRITERIA_UNUSED' OR
        rcs."audience_selection_approach_info":"customer_lists"::STRING      <> 'CRITERIA_UNUSED' OR
        rcs."audience_selection_approach_info":"demographic_info"::STRING    <> 'CRITERIA_UNUSED' OR
        rcs."audience_selection_approach_info":"geo_location"::STRING        <> 'CRITERIA_UNUSED' OR
        rcs."audience_selection_approach_info":"topics_of_interest"::STRING  <> 'CRITERIA_UNUSED'
      )
ORDER BY rs.value:"last_shown"::DATE DESC NULLS LAST
LIMIT 5;