-- Image-type Health ad (verified CY advertiser) that ran in Croatia during 2023
-- and used ALL audience-selection methods (none UNUSED); pick the one with the
-- highest upper bound of impressions.
SELECT t."creative_page_url"
FROM "GOOGLE_ADS"."GOOGLE_ADS_TRANSPARENCY_CENTER"."CREATIVE_STATS" AS t,
     LATERAL FLATTEN( INPUT => PARSE_JSON(t."region_stats") ) AS rs
WHERE t."ad_format_type"               = 'IMAGE'
  AND t."topic"                        ILIKE '%Health%'        -- Health–related topic
  AND t."advertiser_location"          = 'CY'                 -- Cyprus
  AND t."advertiser_verification_status" = 'VERIFIED'
  -- Served in Croatia (HR) between 2023-01-02 and 2023-12-31
  AND rs.value:"region_code"::STRING    = 'HR'
  AND rs.value:"first_shown"::DATE      >  '2023-01-01'
  AND rs.value:"last_shown" ::DATE      <  '2024-01-01'
  -- Impression numbers already available
  AND rs.value:"times_shown_availability_date" IS NULL
  -- All audience-selection criteria actively used
  AND PARSE_JSON(t."audience_selection_approach_info"):"contextual_signals"::STRING  != 'CRITERIA_UNUSED'
  AND PARSE_JSON(t."audience_selection_approach_info"):"customer_lists"   ::STRING  != 'CRITERIA_UNUSED'
  AND PARSE_JSON(t."audience_selection_approach_info"):"demographic_info" ::STRING  != 'CRITERIA_UNUSED'
  AND PARSE_JSON(t."audience_selection_approach_info"):"geo_location"     ::STRING  != 'CRITERIA_UNUSED'
  AND PARSE_JSON(t."audience_selection_approach_info"):"topics_of_interest"::STRING != 'CRITERIA_UNUSED'
ORDER BY rs.value:"times_shown_upper_bound"::INT DESC NULLS LAST
LIMIT 1;