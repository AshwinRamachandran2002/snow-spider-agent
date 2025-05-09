SELECT
       t."creative_page_url"
FROM   GOOGLE_ADS.GOOGLE_ADS_TRANSPARENCY_CENTER."CREATIVE_STATS"  AS t
       , LATERAL FLATTEN(input => t."region_stats")                AS region
       , LATERAL (SELECT TRY_PARSE_JSON(t."audience_selection_approach_info") 
                        AS asi_json)                               AS j
WHERE  t."ad_format_type"                 = 'IMAGE'
  AND  t."advertiser_location"            = 'CY'
  AND  t."advertiser_verification_status" = 'VERIFIED'
  AND  LOWER(t."topic") LIKE '%health%'                     -- Health-related topic
  AND  region.value:"region_code"::STRING  = 'HR'           -- shown in Croatia
  AND  region.value:"first_shown"::DATE   >  '2023-01-01'   -- after Jan-01-2023
  AND  region.value:"last_shown"::DATE    <  '2024-01-01'   -- before Jan-01-2024
  AND  region.value:"times_shown_availability_date" IS NULL -- impressions available
  -- all five targeting dimensions must be used (not CRITERIA_UNUSED)
  AND  j.asi_json:"contextual_signals"::STRING   <> 'CRITERIA_UNUSED'
  AND  j.asi_json:"customer_lists"::STRING       <> 'CRITERIA_UNUSED'
  AND  j.asi_json:"demographic_info"::STRING     <> 'CRITERIA_UNUSED'
  AND  j.asi_json:"geo_location"::STRING         <> 'CRITERIA_UNUSED'
  AND  j.asi_json:"topics_of_interest"::STRING   <> 'CRITERIA_UNUSED'
QUALIFY ROW_NUMBER() OVER (
            ORDER BY region.value:"times_shown_upper_bound"::NUMBER DESC NULLS LAST
        ) = 1;