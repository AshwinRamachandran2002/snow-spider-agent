SELECT
    creative_page_url
FROM (
    SELECT
        cs."creative_page_url"                                          AS creative_page_url,
        rs.value:"times_shown_upper_bound"::NUMBER                      AS times_shown_upper_bound
    FROM GOOGLE_ADS.GOOGLE_ADS_TRANSPARENCY_CENTER.CREATIVE_STATS cs
         , LATERAL FLATTEN ( INPUT => PARSE_JSON(cs."region_stats") ) rs
         , LATERAL ( SELECT PARSE_JSON(cs."audience_selection_approach_info") AS asi )
    WHERE  cs."ad_format_type"              = 'IMAGE'
      AND  cs."topic"                       = 'Health'
      AND  cs."advertiser_verification_status" = 'VERIFIED'
      AND  cs."advertiser_location"         = 'CY'
      AND  rs.value:"region_code"::STRING   = 'HR'                          -- Croatia
      AND  rs.value:"times_shown_availability_date" IS NULL                -- times‑shown data available
      AND  TO_DATE(rs.value:"first_shown"::STRING)  > '2023-01-01'         -- strictly after Jan‑1‑2023
      AND  TO_DATE(rs.value:"last_shown"::STRING)   < '2024-01-01'         -- strictly before Jan‑1‑2024
      AND  asi:"contextual_signals"::STRING      <> 'CRITERIA_UNUSED'
      AND  asi:"customer_lists"::STRING          <> 'CRITERIA_UNUSED'
      AND  asi:"demographic_info"::STRING        <> 'CRITERIA_UNUSED'
      AND  asi:"geo_location"::STRING            <> 'CRITERIA_UNUSED'
      AND  asi:"topics_of_interest"::STRING      <> 'CRITERIA_UNUSED'
)
ORDER BY times_shown_upper_bound DESC NULLS LAST
LIMIT 1;