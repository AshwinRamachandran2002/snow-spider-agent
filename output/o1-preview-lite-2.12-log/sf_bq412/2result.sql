SELECT
  t."creative_page_url" AS "Page_URL",
  TO_DATE(f.value:"first_shown"::STRING, 'YYYY-MM-DD') AS "First_Shown_Time",
  TO_DATE(f.value:"last_shown"::STRING, 'YYYY-MM-DD') AS "Last_Shown_Time",
  d.value:"removal_reason"::STRING AS "Removal_Reason",
  d.value:"violation_category"::STRING AS "Violation_Category",
  ROUND(f.value:"times_shown_lower_bound"::NUMBER, 4) AS "Lower_Bound_Shown_Times",
  ROUND(f.value:"times_shown_upper_bound"::NUMBER, 4) AS "Upper_Bound_Shown_Times"
FROM
  "GOOGLE_ADS"."GOOGLE_ADS_TRANSPARENCY_CENTER"."REMOVED_CREATIVE_STATS" t,
  LATERAL FLATTEN(input => t."region_stats") f,
  LATERAL FLATTEN(input => t."disapproval") d
WHERE
  f.value:"region_code"::STRING = 'HR'
  AND f.value:"times_shown_lower_bound"::NUMBER > 10000
  AND f.value:"times_shown_upper_bound"::NUMBER < 25000
  AND (
    t."audience_selection_approach_info":"demographic_info"::STRING IN ('CRITERIA_INCLUDED', 'CRITERIA_INCLUDED_AND_EXCLUDED')
    OR t."audience_selection_approach_info":"geo_location"::STRING IN ('CRITERIA_INCLUDED', 'CRITERIA_INCLUDED_AND_EXCLUDED')
    OR t."audience_selection_approach_info":"contextual_signals"::STRING IN ('CRITERIA_INCLUDED', 'CRITERIA_INCLUDED_AND_EXCLUDED')
    OR t."audience_selection_approach_info":"customer_lists"::STRING IN ('CRITERIA_INCLUDED', 'CRITERIA_INCLUDED_AND_EXCLUDED')
    OR t."audience_selection_approach_info":"topics_of_interest"::STRING IN ('CRITERIA_INCLUDED', 'CRITERIA_INCLUDED_AND_EXCLUDED')
  )
ORDER BY
  TO_DATE(f.value:"last_shown"::STRING, 'YYYY-MM-DD') DESC NULLS LAST
LIMIT 5;