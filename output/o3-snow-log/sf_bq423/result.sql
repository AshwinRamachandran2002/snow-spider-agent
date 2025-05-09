WITH candidate_ads AS (
    SELECT
        c."creative_page_url",
        rs.value:"times_shown_upper_bound"::NUMBER       AS times_shown_upper_bound,
        rs.value:"first_shown"::DATE                    AS first_shown,
        rs.value:"last_shown"::DATE                     AS last_shown
    FROM GOOGLE_ADS.GOOGLE_ADS_TRANSPARENCY_CENTER.CREATIVE_STATS            AS c
    -- unpack the per-region statistics
    CROSS JOIN LATERAL FLATTEN ( INPUT => c."region_stats" )                 AS rs
    -- unpack the audience-selection object
    CROSS JOIN LATERAL ( SELECT PARSE_JSON(c."audience_selection_approach_info") AS asi ) asi_tbl
    WHERE
          c."ad_format_type"               = 'IMAGE'          -- image-type ad
      AND c."topic"                        = 'Health'         -- topic Health
      AND c."advertiser_verification_status" = 'VERIFIED'     -- verified advertiser
      AND c."advertiser_location"          = 'CY'             -- advertiser in Cyprus
      AND rs.value:"region_code"::STRING   = 'HR'             -- shown in Croatia
      AND rs.value:"times_shown_availability_date" IS NULL    -- times-shown data already available
      AND rs.value:"first_shown"::DATE  > '2023-01-01'        -- first shown after 1-Jan-2023
      AND rs.value:"last_shown"::DATE   < '2024-01-01'        -- last shown before 1-Jan-2024
      -- every audience-selection method must be used (≠ CRITERIA_UNUSED)
      AND asi_tbl.asi:"contextual_signals"::STRING   <> 'CRITERIA_UNUSED'
      AND asi_tbl.asi:"customer_lists"::STRING       <> 'CRITERIA_UNUSED'
      AND asi_tbl.asi:"demographic_info"::STRING     <> 'CRITERIA_UNUSED'
      AND asi_tbl.asi:"geo_location"::STRING         <> 'CRITERIA_UNUSED'
      AND asi_tbl.asi:"topics_of_interest"::STRING   <> 'CRITERIA_UNUSED'
)
SELECT "creative_page_url"
FROM   candidate_ads
ORDER  BY times_shown_upper_bound DESC NULLS LAST
LIMIT 1;