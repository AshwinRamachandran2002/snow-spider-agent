WITH eligible AS (
    SELECT
        cs."creative_page_url",
        rs.value:"times_shown_upper_bound"::INTEGER AS "upper_bound"
    FROM  GOOGLE_ADS.GOOGLE_ADS_TRANSPARENCY_CENTER.CREATIVE_STATS cs,
          LATERAL FLATTEN(input => cs."region_stats") rs
    WHERE cs."ad_format_type"                 = 'IMAGE'
      AND cs."topic"                          ILIKE '%Health%'
      AND cs."advertiser_location"            = 'CY'
      AND cs."advertiser_verification_status" = 'VERIFIED'
      AND rs.value:"region_code"::STRING      = 'HR'                  -- Croatia
      AND rs.value:"first_shown"::DATE        >  '2023-01-01'
      AND rs.value:"last_shown"::DATE         <  '2024-01-01'
      AND rs.value:"times_shown_availability_date" IS NULL            -- data available
      -- all five selection methods must be used (≠ UNUSED)
      AND cs."audience_selection_approach_info":"contextual_signals"::STRING NOT ILIKE '%UNUSED%'
      AND cs."audience_selection_approach_info":"customer_lists"::STRING     NOT ILIKE '%UNUSED%'
      AND cs."audience_selection_approach_info":"demographic_info"::STRING   NOT ILIKE '%UNUSED%'
      AND cs."audience_selection_approach_info":"geo_location"::STRING       NOT ILIKE '%UNUSED%'
      AND cs."audience_selection_approach_info":"topics_of_interest"::STRING NOT ILIKE '%UNUSED%'
)
SELECT "creative_page_url"
FROM   eligible
QUALIFY ROW_NUMBER() OVER (ORDER BY "upper_bound" DESC NULLS LAST) = 1;