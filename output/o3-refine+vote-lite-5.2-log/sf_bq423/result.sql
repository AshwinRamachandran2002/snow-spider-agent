WITH candidate_ads AS (
    SELECT
        cs."creative_page_url",
        rs.value:"times_shown_upper_bound"::NUMBER        AS times_shown_upper_bound
    FROM GOOGLE_ADS.GOOGLE_ADS_TRANSPARENCY_CENTER.CREATIVE_STATS cs
         ,LATERAL FLATTEN(input => cs."region_stats") rs
    WHERE
          cs."ad_format_type"                         = 'IMAGE'                -- image–type ad
      AND cs."topic"                                  = 'Health'               -- topic of Health
      AND cs."advertiser_verification_status"         = 'VERIFIED'             -- advertiser verified
      AND cs."advertiser_location"                    = 'CY'                   -- advertiser in Cyprus
      -- region‑level filters (Croatia, date window, times shown already available)
      AND rs.value:"region_code"::STRING              = 'HR'
      AND rs.value:"first_shown"::DATE                >  DATE '2023-01-01'
      AND rs.value:"last_shown"::DATE                 <  DATE '2024-01-01'
      AND rs.value:"times_shown_availability_date"    IS NULL                  -- times‑shown data available
      -- all selection methods must be used (none = CRITERIA_UNUSED)
      AND cs."audience_selection_approach_info":"contextual_signals"::STRING   <> 'CRITERIA_UNUSED'
      AND cs."audience_selection_approach_info":"customer_lists"::STRING       <> 'CRITERIA_UNUSED'
      AND cs."audience_selection_approach_info":"demographic_info"::STRING     <> 'CRITERIA_UNUSED'
      AND cs."audience_selection_approach_info":"geo_location"::STRING         <> 'CRITERIA_UNUSED'
      AND cs."audience_selection_approach_info":"topics_of_interest"::STRING   <> 'CRITERIA_UNUSED'
)
SELECT "creative_page_url"
FROM   candidate_ads
ORDER  BY times_shown_upper_bound DESC NULLS LAST
LIMIT 1;