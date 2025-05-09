SELECT DISTINCT
       r."creative_page_url",
       reg.value:"first_shown"::DATE            AS "first_shown",
       reg.value:"last_shown"::DATE             AS "last_shown",
       disp.value:"removal_reason"::STRING      AS "removal_reason",
       disp.value:"violation_category"::STRING  AS "violation_category",
       reg.value:"times_shown_lower_bound"::INT AS "lower_bound",
       reg.value:"times_shown_upper_bound"::INT AS "upper_bound"
FROM   "GOOGLE_ADS"."GOOGLE_ADS_TRANSPARENCY_CENTER"."REMOVED_CREATIVE_STATS"  r,
       LATERAL FLATTEN(input => r."region_stats")                              reg,
       LATERAL FLATTEN(input => r."disapproval")                               disp
WHERE  reg.value:"region_code"::STRING = 'HR'
  AND  reg.value:"times_shown_lower_bound"::INT > 10000
  AND  reg.value:"times_shown_upper_bound"::INT < 25000
  AND  reg.value:"times_shown_availability_date" IS NULL
  AND (
        NVL(r."audience_selection_approach_info":"contextual_signals"::STRING, 'CRITERIA_UNUSED') <> 'CRITERIA_UNUSED'
     OR NVL(r."audience_selection_approach_info":"customer_lists"::STRING,     'CRITERIA_UNUSED') <> 'CRITERIA_UNUSED'
     OR NVL(r."audience_selection_approach_info":"demographic_info"::STRING,   'CRITERIA_UNUSED') <> 'CRITERIA_UNUSED'
     OR NVL(r."audience_selection_approach_info":"geo_location"::STRING,       'CRITERIA_UNUSED') <> 'CRITERIA_UNUSED'
     OR NVL(r."audience_selection_approach_info":"topics_of_interest"::STRING, 'CRITERIA_UNUSED') <> 'CRITERIA_UNUSED'
      )
ORDER BY CAST(reg.value:"last_shown" AS DATE) DESC NULLS LAST
LIMIT 5;