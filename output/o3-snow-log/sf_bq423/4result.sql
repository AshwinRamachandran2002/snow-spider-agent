WITH candidates AS (
    SELECT
        c."creative_page_url",
        reg.value:"times_shown_upper_bound"::NUMBER      AS upper_bound
    FROM GOOGLE_ADS.GOOGLE_ADS_TRANSPARENCY_CENTER.CREATIVE_STATS  AS c
         ,LATERAL FLATTEN( INPUT => PARSE_JSON(c."region_stats") ) AS reg
    WHERE c."ad_format_type"                     = 'IMAGE'
      AND c."topic"                              = 'Health'
      AND c."advertiser_verification_status"     = 'VERIFIED'
      AND c."advertiser_location"                = 'CY'
      -- Region must be Croatia
      AND reg.value:"region_code"::STRING        = 'HR'
      -- Show-date window strictly inside 2023
      AND reg.value:"first_shown"::DATE          > '2023-01-01'
      AND reg.value:"last_shown"::DATE           < '2024-01-01'
      -- Times-shown data already available
      AND reg.value:"times_shown_availability_date" IS NULL
      -- All audience-selection approaches used (none are UNUSED)
      AND COALESCE( PARSE_JSON(c."audience_selection_approach_info"):"contextual_signals"::STRING ,'CRITERIA_UNUSED') <> 'CRITERIA_UNUSED'
      AND COALESCE( PARSE_JSON(c."audience_selection_approach_info"):"customer_lists"     ::STRING ,'CRITERIA_UNUSED') <> 'CRITERIA_UNUSED'
      AND COALESCE( PARSE_JSON(c."audience_selection_approach_info"):"demographic_info"   ::STRING ,'CRITERIA_UNUSED') <> 'CRITERIA_UNUSED'
      AND COALESCE( PARSE_JSON(c."audience_selection_approach_info"):"geo_location"       ::STRING ,'CRITERIA_UNUSED') <> 'CRITERIA_UNUSED'
      AND COALESCE( PARSE_JSON(c."audience_selection_approach_info"):"topics_of_interest" ::STRING ,'CRITERIA_UNUSED') <> 'CRITERIA_UNUSED'
)
SELECT "creative_page_url"
FROM   candidates
QUALIFY ROW_NUMBER() OVER (ORDER BY upper_bound DESC NULLS LAST) = 1;