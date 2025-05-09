SELECT  
    t."creative_page_url"                              AS "page_url",
    f.value:"first_shown"::DATE                        AS "first_shown",
    f.value:"last_shown"::DATE                         AS "last_shown",
    d.value:"removal_reason"::STRING                   AS "removal_reason",
    d.value:"violation_category"::STRING               AS "violation_category",
    f.value:"times_shown_lower_bound"::INTEGER         AS "times_shown_lower_bound",
    f.value:"times_shown_upper_bound"::INTEGER         AS "times_shown_upper_bound"
FROM "GOOGLE_ADS"."GOOGLE_ADS_TRANSPARENCY_CENTER"."REMOVED_CREATIVE_STATS"  t
     , LATERAL FLATTEN(input => t."region_stats")      f
     , LATERAL FLATTEN(input => t."disapproval")       d
WHERE f.value:"region_code"::STRING = 'HR'
  AND f.value:"times_shown_availability_date" IS NULL
  AND f.value:"times_shown_lower_bound"::INTEGER > 10000
  AND f.value:"times_shown_upper_bound"::INTEGER < 25000
  AND (
        t."audience_selection_approach_info":"contextual_signals"::STRING <> 'CRITERIA_UNUSED' OR
        t."audience_selection_approach_info":"customer_lists"::STRING     <> 'CRITERIA_UNUSED' OR
        t."audience_selection_approach_info":"demographic_info"::STRING   <> 'CRITERIA_UNUSED' OR
        t."audience_selection_approach_info":"geo_location"::STRING       <> 'CRITERIA_UNUSED' OR
        t."audience_selection_approach_info":"topics_of_interest"::STRING <> 'CRITERIA_UNUSED'
      )
ORDER BY f.value:"last_shown"::DATE DESC NULLS LAST
LIMIT 5;