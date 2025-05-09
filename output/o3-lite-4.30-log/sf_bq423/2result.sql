SELECT
       c."creative_page_url" AS page_url
FROM   "GOOGLE_ADS"."GOOGLE_ADS_TRANSPARENCY_CENTER"."CREATIVE_STATS"  c,
       LATERAL FLATTEN(input => PARSE_JSON(c."region_stats"))           r
WHERE  r.value:"region_code" = 'HR'                                   -- Croatia
  AND  r.value:"first_shown"::DATE  > '2023-01-01'                    -- after Jan‑1‑2023
  AND  r.value:"last_shown"::DATE   < '2024-01-01'                    -- before Jan‑1‑2024
  AND  r.value:"times_shown_availability_date" IS NULL                -- data available
  AND  c."ad_format_type"                = 'IMAGE'                    -- image ads
  AND  c."topic"                          ILIKE '%Health%'            -- Health topic
  AND  c."advertiser_location"            = 'CY'                      -- Cyprus
  AND  c."advertiser_verification_status" = 'VERIFIED'                -- verified advertiser
  -- ensure every audience‑selection method is used (≠ 'CRITERIA_UNUSED')
  AND  PARSE_JSON(c."audience_selection_approach_info"):"demographic_info"::STRING   <> 'CRITERIA_UNUSED'
  AND  PARSE_JSON(c."audience_selection_approach_info"):"geo_location"::STRING       <> 'CRITERIA_UNUSED'
  AND  PARSE_JSON(c."audience_selection_approach_info"):"contextual_signals"::STRING <> 'CRITERIA_UNUSED'
  AND  PARSE_JSON(c."audience_selection_approach_info"):"customer_lists"::STRING     <> 'CRITERIA_UNUSED'
  AND  COALESCE(
         PARSE_JSON(c."audience_selection_approach_info"):"topics_of_interest",
         PARSE_JSON(c."audience_selection_approach_info"):"topics"
       )::STRING                                                        <> 'CRITERIA_UNUSED'
ORDER BY r.value:"times_shown_upper_bound"::NUMBER DESC NULLS LAST      -- highest impressions
LIMIT 1;