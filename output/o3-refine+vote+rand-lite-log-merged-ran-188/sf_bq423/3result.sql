WITH ads AS (
    SELECT
        cs."creative_page_url"                                   AS creative_page_url,
        rs.value:"times_shown_upper_bound"::INT                  AS times_shown_upper_bound
    FROM GOOGLE_ADS.GOOGLE_ADS_TRANSPARENCY_CENTER.CREATIVE_STATS cs,
         LATERAL FLATTEN(INPUT => cs."region_stats") rs
    WHERE
          cs."ad_format_type" = 'IMAGE'
      AND cs."topic" = 'Health'
      AND cs."advertiser_verification_status" = 'VERIFIED'
      AND cs."advertiser_location" = 'CY'
      -- every listed targeting method must be used (not 'CRITERIA_UNUSED')
      AND COALESCE(cs."audience_selection_approach_info":"demographic_info"::STRING,    'CRITERIA_UNUSED') <> 'CRITERIA_UNUSED'
      AND COALESCE(cs."audience_selection_approach_info":"geo_location"::STRING,       'CRITERIA_UNUSED') <> 'CRITERIA_UNUSED'
      AND COALESCE(cs."audience_selection_approach_info":"contextual_signals"::STRING, 'CRITERIA_UNUSED') <> 'CRITERIA_UNUSED'
      AND COALESCE(cs."audience_selection_approach_info":"customer_lists"::STRING,     'CRITERIA_UNUSED') <> 'CRITERIA_UNUSED'
      AND COALESCE(cs."audience_selection_approach_info":"topics_of_interest"::STRING, 'CRITERIA_UNUSED') <> 'CRITERIA_UNUSED'
      -- served in Croatia within the specified period
      AND rs.value:"region_code"::STRING = 'HR'
      AND rs.value:"first_shown"::DATE  > '2023-01-01'
      AND rs.value:"last_shown"::DATE   < '2024-01-01'
      -- times‑shown data already available
      AND rs.value:"times_shown_availability_date" IS NULL
)
SELECT creative_page_url
FROM ads
ORDER BY times_shown_upper_bound DESC NULLS LAST, creative_page_url
LIMIT 1;