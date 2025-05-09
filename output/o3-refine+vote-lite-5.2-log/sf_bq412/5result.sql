SELECT
    r."creative_page_url",
    rs.value:"first_shown"::DATE          AS "first_shown",
    rs.value:"last_shown"::DATE           AS "last_shown",
    d.value:"removal_reason"::STRING      AS "removal_reason",
    d.value:"violation_category"::STRING  AS "violation_category",
    rs.value:"times_shown_lower_bound"::NUMBER AS "times_shown_lower_bound",
    rs.value:"times_shown_upper_bound"::NUMBER AS "times_shown_upper_bound"
FROM  GOOGLE_ADS.GOOGLE_ADS_TRANSPARENCY_CENTER.REMOVED_CREATIVE_STATS  AS r
      ,LATERAL FLATTEN(INPUT => r."region_stats")  AS rs
      ,LATERAL FLATTEN(INPUT => r."disapproval")   AS d
WHERE rs.value:"region_code"::STRING                     = 'HR'                 -- Croatia
  AND rs.value:"times_shown_availability_date"           IS NULL                -- availability date is null
  AND rs.value:"times_shown_lower_bound"::NUMBER         > 10000
  AND rs.value:"times_shown_upper_bound"::NUMBER         < 25000
  AND (   COALESCE(r."audience_selection_approach_info":"demographic_info"::STRING      ,'CRITERIA_UNUSED') <> 'CRITERIA_UNUSED'
       OR COALESCE(r."audience_selection_approach_info":"geo_location"::STRING         ,'CRITERIA_UNUSED') <> 'CRITERIA_UNUSED'
       OR COALESCE(r."audience_selection_approach_info":"contextual_signals"::STRING   ,'CRITERIA_UNUSED') <> 'CRITERIA_UNUSED'
       OR COALESCE(r."audience_selection_approach_info":"customer_lists"::STRING       ,'CRITERIA_UNUSED') <> 'CRITERIA_UNUSED'
       OR COALESCE(r."audience_selection_approach_info":"topics_of_interest"::STRING   ,'CRITERIA_UNUSED') <> 'CRITERIA_UNUSED'
      )
QUALIFY ROW_NUMBER() OVER (PARTITION BY r."creative_page_url" ORDER BY d.index) = 1   -- keep one row per ad
ORDER BY "last_shown" DESC NULLS LAST
LIMIT 5;