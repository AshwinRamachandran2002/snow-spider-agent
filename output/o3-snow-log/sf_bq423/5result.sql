/*  Ad on topic Health, image type, verified CY advertiser,
    served in HR between 2023-01-01 and 2024-01-01,
    with available times-shown data and all targeting criteria used.
    Return the page-URL of the ad that has the highest upper-bound of times shown. */
SELECT
       c."creative_page_url"
FROM   GOOGLE_ADS.GOOGLE_ADS_TRANSPARENCY_CENTER."CREATIVE_STATS"  AS c,
       LATERAL FLATTEN( INPUT => c."region_stats")                AS r       -- one row per region
WHERE  c."ad_format_type"               = 'IMAGE'                          -- image-type ad
  AND  UPPER(c."topic")                 LIKE '%HEALTH%'                    -- Health topic
  AND  c."advertiser_verification_status" = 'VERIFIED'                     -- verified advertiser
  AND  c."advertiser_location"          = 'CY'                             -- advertiser located in Cyprus
  /*  Region-specific filters (Croatia) */
  AND  r.value:"region_code"::STRING    = 'HR'                             -- shown in Croatia
  AND  r.value:"first_shown"::DATE      >  '2023-01-01'                    -- first shown strictly after 2023-01-01
  AND  r.value:"last_shown"::DATE       <  '2024-01-01'                    -- last shown strictly before 2024-01-01
  AND  r.value:"times_shown_availability_date" IS NULL                     -- times-shown data already available
  /*  All targeting approaches must be used ( none = CRITERIA_UNUSED ) */
  AND  COALESCE(c."audience_selection_approach_info":"demographic_info"::STRING        , 'CRITERIA_UNUSED') <> 'CRITERIA_UNUSED'
  AND  COALESCE(c."audience_selection_approach_info":"geo_location"::STRING            , 'CRITERIA_UNUSED') <> 'CRITERIA_UNUSED'
  AND  COALESCE(c."audience_selection_approach_info":"contextual_signals"::STRING      , 'CRITERIA_UNUSED') <> 'CRITERIA_UNUSED'
  AND  COALESCE(c."audience_selection_approach_info":"customer_lists"::STRING          , 'CRITERIA_UNUSED') <> 'CRITERIA_UNUSED'
  AND  COALESCE(c."audience_selection_approach_info":"topics_of_interest"::STRING      , 'CRITERIA_UNUSED') <> 'CRITERIA_UNUSED'
ORDER BY r.value:"times_shown_upper_bound"::NUMBER DESC NULLS LAST         -- highest exposure first
LIMIT 1;