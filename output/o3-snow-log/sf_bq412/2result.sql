SELECT
    t."creative_page_url"                                                        AS "page_url",
    rs.value:"first_shown"::DATE                                                AS "first_shown_time",
    rs.value:"last_shown"::DATE                                                 AS "last_shown_time",
    t."disapproval"[0]:"removal_reason"::STRING                                 AS "removal_reason",
    t."disapproval"[0]:"violation_category"::STRING                             AS "violation_category",
    rs.value:"times_shown_lower_bound"::INT                                     AS "times_shown_lower_bound",
    rs.value:"times_shown_upper_bound"::INT                                     AS "times_shown_upper_bound"
FROM  GOOGLE_ADS.GOOGLE_ADS_TRANSPARENCY_CENTER."REMOVED_CREATIVE_STATS"  AS t,
      LATERAL FLATTEN( INPUT => t."region_stats" )                           AS rs
WHERE rs.value:"region_code"::STRING = 'HR'
  AND rs.value:"times_shown_availability_date" IS NULL
  AND rs.value:"times_shown_lower_bound"::INT  > 10000
  AND rs.value:"times_shown_upper_bound"::INT  < 25000
  AND (
        COALESCE(t."audience_selection_approach_info":"contextual_signals"::STRING , 'CRITERIA_UNUSED')            <> 'CRITERIA_UNUSED'
     OR COALESCE(t."audience_selection_approach_info":"customer_lists"::STRING     , 'CRITERIA_UNUSED')            <> 'CRITERIA_UNUSED'
     OR COALESCE(t."audience_selection_approach_info":"demographic_info"::STRING   , 'CRITERIA_UNUSED')            <> 'CRITERIA_UNUSED'
     OR COALESCE(t."audience_selection_approach_info":"geo_location"::STRING       , 'CRITERIA_UNUSED')            <> 'CRITERIA_UNUSED'
     OR COALESCE(t."audience_selection_approach_info":"topics_of_interest"::STRING , 'CRITERIA_UNUSED')            <> 'CRITERIA_UNUSED'
      )
ORDER BY rs.value:"last_shown"::DATE DESC NULLS LAST
LIMIT 5;