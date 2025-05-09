SELECT
    t."creative_page_url"                                                 AS "page_url",
    rs.value:"first_shown"::STRING                                        AS "first_shown",
    rs.value:"last_shown"::STRING                                         AS "last_shown",
    dis.value:"removal_reason"::STRING                                    AS "removal_reason",
    dis.value:"violation_category"::STRING                                AS "violation_category",
    rs.value:"times_shown_lower_bound"::NUMBER                            AS "times_shown_lower_bound",
    rs.value:"times_shown_upper_bound"::NUMBER                            AS "times_shown_upper_bound"
FROM "GOOGLE_ADS"."GOOGLE_ADS_TRANSPARENCY_CENTER"."REMOVED_CREATIVE_STATS" t
     , LATERAL FLATTEN(input => t."region_stats") rs
     , LATERAL FLATTEN(input => t."disapproval")  dis
WHERE rs.value:"region_code"::STRING = 'HR'
  AND rs.value:"times_shown_lower_bound"::NUMBER > 10000
  AND rs.value:"times_shown_upper_bound"::NUMBER < 25000
  AND rs.value:"times_shown_availability_date" IS NULL
  AND (
         t."audience_selection_approach_info":"contextual_signals"::STRING <> 'CRITERIA_UNUSED'
      OR t."audience_selection_approach_info":"customer_lists"::STRING     <> 'CRITERIA_UNUSED'
      OR t."audience_selection_approach_info":"demographic_info"::STRING   <> 'CRITERIA_UNUSED'
      OR t."audience_selection_approach_info":"geo_location"::STRING       <> 'CRITERIA_UNUSED'
      OR t."audience_selection_approach_info":"topics_of_interest"::STRING <> 'CRITERIA_UNUSED'
      )
ORDER BY rs.value:"last_shown"::DATE DESC NULLS LAST
LIMIT 5;