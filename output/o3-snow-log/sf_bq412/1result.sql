SELECT
    r."creative_page_url"                                            AS "page_url",
    rs.value:"first_shown"::DATE                                     AS "first_shown",
    rs.value:"last_shown"::DATE                                      AS "last_shown",
    d.value:"removal_reason"::STRING                                 AS "removal_reason",
    d.value:"violation_category"::STRING                             AS "violation_category",
    rs.value:"times_shown_lower_bound"::NUMBER                       AS "times_shown_lower_bound",
    rs.value:"times_shown_upper_bound"::NUMBER                       AS "times_shown_upper_bound"
FROM  GOOGLE_ADS.GOOGLE_ADS_TRANSPARENCY_CENTER."REMOVED_CREATIVE_STATS"   r
      ,LATERAL FLATTEN(input => r."region_stats")                              rs
      ,LATERAL FLATTEN(input => r."disapproval")                               d
WHERE rs.value:"region_code"::STRING = 'HR'                                               -- Croatia
  AND rs.value:"times_shown_availability_date" IS NULL                                    -- availability date is null / not present
  AND rs.value:"times_shown_lower_bound"::NUMBER  > 10000                                 -- > 10 000
  AND rs.value:"times_shown_upper_bound"::NUMBER  < 25000                                 -- < 25 000
  AND (                                                                                -- at least one approach not UNUSED
         r."audience_selection_approach_info":contextual_signals::STRING   <> 'CRITERIA_UNUSED'
      OR r."audience_selection_approach_info":customer_lists::STRING       <> 'CRITERIA_UNUSED'
      OR r."audience_selection_approach_info":demographic_info::STRING     <> 'CRITERIA_UNUSED'
      OR r."audience_selection_approach_info":geo_location::STRING         <> 'CRITERIA_UNUSED'
      OR r."audience_selection_approach_info":topics_of_interest::STRING   <> 'CRITERIA_UNUSED'
      )
ORDER BY "last_shown" DESC NULLS LAST
LIMIT 5;