SELECT
    t."creative_page_url"                                    AS page_url,
    rs.value:"first_shown"::DATE                             AS first_shown_time,
    rs.value:"last_shown"::DATE                              AS last_shown_time,
    dp.value:"removal_reason"::STRING                        AS removal_reason,
    dp.value:"violation_category"::STRING                    AS violation_category,
    rs.value:"times_shown_lower_bound"::INTEGER              AS times_shown_lower_bound,
    rs.value:"times_shown_upper_bound"::INTEGER              AS times_shown_upper_bound
FROM  "GOOGLE_ADS"."GOOGLE_ADS_TRANSPARENCY_CENTER"."REMOVED_CREATIVE_STATS" t
      ,LATERAL FLATTEN(input => t."region_stats")            rs
      ,LATERAL FLATTEN(input => t."disapproval", outer => TRUE) dp
WHERE rs.value:"region_code"::STRING = 'HR'
  AND rs.value:"times_shown_availability_date" IS NULL
  AND rs.value:"times_shown_lower_bound"::INTEGER > 10000
  AND rs.value:"times_shown_upper_bound"::INTEGER < 25000
  AND (
        NVL(t."audience_selection_approach_info":"demographic_info"::STRING,   'UNUSED') NOT ILIKE '%UNUSED%' OR
        NVL(t."audience_selection_approach_info":"geo_location"::STRING,       'UNUSED') NOT ILIKE '%UNUSED%' OR
        NVL(t."audience_selection_approach_info":"contextual_signals"::STRING, 'UNUSED') NOT ILIKE '%UNUSED%' OR
        NVL(t."audience_selection_approach_info":"customer_lists"::STRING,     'UNUSED') NOT ILIKE '%UNUSED%' OR
        NVL(t."audience_selection_approach_info":"topics_of_interest"::STRING, 'UNUSED') NOT ILIKE '%UNUSED%'
      )
QUALIFY ROW_NUMBER() OVER (PARTITION BY t."creative_page_url"
                           ORDER BY rs.value:"last_shown"::DATE DESC) = 1
ORDER BY last_shown_time DESC NULLS LAST
LIMIT 5;