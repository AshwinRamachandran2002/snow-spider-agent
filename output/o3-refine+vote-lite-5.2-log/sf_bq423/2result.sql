WITH eligible_ads AS (
    SELECT
        cs."creative_page_url",
        rs.value:"times_shown_upper_bound"::NUMBER AS upper_bound
    FROM GOOGLE_ADS.GOOGLE_ADS_TRANSPARENCY_CENTER.CREATIVE_STATS cs
    ,     LATERAL FLATTEN(input => PARSE_JSON(cs."region_stats")) rs
    WHERE rs.value:"region_code" = 'HR'                                          -- served in Croatia
      AND rs.value:"times_shown_availability_date" IS NULL                       -- times‑shown data already available
      AND rs.value:"first_shown"::DATE  > '2023-01-01'                           -- first shown strictly after 01‑Jan‑2023
      AND rs.value:"last_shown" ::DATE  < '2024-01-01'                           -- last shown  strictly before 01‑Jan‑2024
      AND cs."ad_format_type"               = 'IMAGE'                            -- image‑type ad
      AND cs."topic"                        = 'Health'                           -- topic of Health
      AND cs."advertiser_verification_status" = 'VERIFIED'                       -- verified advertiser
      AND cs."advertiser_location"          = 'CY'                               -- advertiser located in Cyprus
      -- all audience‑selection approaches are used (i.e., not CRITERIA_UNUSED)
      AND COALESCE(PARSE_JSON(cs."audience_selection_approach_info"):"contextual_signals", 'CRITERIA_UNUSED') <> 'CRITERIA_UNUSED'
      AND COALESCE(PARSE_JSON(cs."audience_selection_approach_info"):"customer_lists"    , 'CRITERIA_UNUSED') <> 'CRITERIA_UNUSED'
      AND COALESCE(PARSE_JSON(cs."audience_selection_approach_info"):"demographic_info"  , 'CRITERIA_UNUSED') <> 'CRITERIA_UNUSED'
      AND COALESCE(PARSE_JSON(cs."audience_selection_approach_info"):"geo_location"      , 'CRITERIA_UNUSED') <> 'CRITERIA_UNUSED'
      AND COALESCE(PARSE_JSON(cs."audience_selection_approach_info"):"topics_of_interest", 'CRITERIA_UNUSED') <> 'CRITERIA_UNUSED'
)
SELECT "creative_page_url"
FROM   eligible_ads
ORDER BY upper_bound DESC NULLS LAST          -- highest upper‑bound of times shown first
LIMIT 1;