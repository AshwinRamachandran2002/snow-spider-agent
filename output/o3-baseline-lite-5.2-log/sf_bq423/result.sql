WITH filtered_ads AS (
    SELECT
        cs."creative_page_url"                                                AS creative_page_url,
        reg.value:"times_shown_upper_bound"::NUMBER                           AS times_shown_upper_bound
    FROM GOOGLE_ADS.GOOGLE_ADS_TRANSPARENCY_CENTER.CREATIVE_STATS cs
         , LATERAL FLATTEN (INPUT => PARSE_JSON(cs."region_stats")) reg
    WHERE cs."ad_format_type" = 'IMAGE'
      AND LOWER(cs."topic") LIKE '%health%'                           -- Health topic
      AND cs."advertiser_verification_status" = 'VERIFIED'            -- verified advertiser
      AND cs."advertiser_location" = 'CY'                             -- advertiser in Cyprus
      AND reg.value:"region_code"::STRING = 'HR'                      -- shown in Croatia
      AND reg.value:"first_shown"::DATE  > '2023-01-01'               -- first shown strictly after 2023‑01‑01
      AND reg.value:"last_shown"::DATE   < '2024-01-01'               -- last shown strictly before 2024‑01‑01
      AND reg.value:"times_shown_availability_date" IS NULL           -- times‑shown data available
      -- every targeting method is used (none are UNUSED)
      AND COALESCE(PARSE_JSON(cs."audience_selection_approach_info"):"demographic_info"::STRING  , 'CRITERIA_UNUSED') != 'CRITERIA_UNUSED'
      AND COALESCE(PARSE_JSON(cs."audience_selection_approach_info"):"geo_location"::STRING      , 'CRITERIA_UNUSED') != 'CRITERIA_UNUSED'
      AND COALESCE(PARSE_JSON(cs."audience_selection_approach_info"):"contextual_signals"::STRING, 'CRITERIA_UNUSED') != 'CRITERIA_UNUSED'
      AND COALESCE(PARSE_JSON(cs."audience_selection_approach_info"):"customer_lists"::STRING    , 'CRITERIA_UNUSED') != 'CRITERIA_UNUSED'
      AND COALESCE(PARSE_JSON(cs."audience_selection_approach_info"):"topics_of_interest"::STRING, 'CRITERIA_UNUSED') != 'CRITERIA_UNUSED'
)
SELECT creative_page_url
FROM   filtered_ads
ORDER  BY times_shown_upper_bound DESC NULLS LAST, creative_page_url
LIMIT  1;