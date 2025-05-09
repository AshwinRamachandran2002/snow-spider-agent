WITH ads AS (
    SELECT
        cs."creative_page_url",
        rs.value:"times_shown_upper_bound"::NUMBER         AS upper_bound
    FROM GOOGLE_ADS.GOOGLE_ADS_TRANSPARENCY_CENTER.CREATIVE_STATS cs,
         LATERAL FLATTEN(input => TRY_PARSE_JSON(cs."region_stats")) rs
    WHERE
          cs."ad_format_type"                = 'IMAGE'
      AND cs."topic"                         = 'Health'
      AND cs."advertiser_verification_status"= 'VERIFIED'
      AND cs."advertiser_location"           = 'CY'
      -- -------- region-level requirements --------
      AND rs.value:"region_code"::STRING     = 'HR'                    -- shown in Croatia
      AND rs.value:"first_shown"::DATE       >  '2023-01-01'           -- strictly after
      AND rs.value:"last_shown"::DATE        <  '2024-01-01'           -- strictly before
      AND rs.value:"times_shown_availability_date" IS NULL             -- times-shown data available
      -- -------- audience-selection requirements --------
      AND COALESCE(TRY_PARSE_JSON(cs."audience_selection_approach_info"):"contextual_signals"::STRING, 'CRITERIA_UNUSED')       <> 'CRITERIA_UNUSED'
      AND COALESCE(TRY_PARSE_JSON(cs."audience_selection_approach_info"):"customer_lists"::STRING,        'CRITERIA_UNUSED')     <> 'CRITERIA_UNUSED'
      AND COALESCE(TRY_PARSE_JSON(cs."audience_selection_approach_info"):"demographic_info"::STRING,      'CRITERIA_UNUSED')     <> 'CRITERIA_UNUSED'
      AND COALESCE(TRY_PARSE_JSON(cs."audience_selection_approach_info"):"geo_location"::STRING,          'CRITERIA_UNUSED')     <> 'CRITERIA_UNUSED'
      AND COALESCE(TRY_PARSE_JSON(cs."audience_selection_approach_info"):"topics_of_interest"::STRING,    'CRITERIA_UNUSED')     <> 'CRITERIA_UNUSED'
)
SELECT "creative_page_url"
FROM ads
ORDER BY upper_bound DESC NULLS LAST
LIMIT 1;