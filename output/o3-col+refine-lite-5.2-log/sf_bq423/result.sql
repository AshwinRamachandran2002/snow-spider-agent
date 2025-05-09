SELECT  result."creative_page_url"
FROM   (
        SELECT  c."creative_page_url",
                r.value:"times_shown_upper_bound"::NUMBER AS "times_shown_upper_bound"
        FROM    GOOGLE_ADS.GOOGLE_ADS_TRANSPARENCY_CENTER.CREATIVE_STATS  c,
                LATERAL FLATTEN( INPUT => PARSE_JSON(c."region_stats") ) r
        WHERE   c."ad_format_type"                        = 'IMAGE'
          AND   c."advertiser_location"                   = 'CY'
          AND   c."advertiser_verification_status"        = 'VERIFIED'
          AND   c."topic" ILIKE '%Health%'
          AND   r.value:"region_code"::STRING             = 'HR'          -- Croatia
          AND   r.value:"times_shown_availability_date"   IS NULL         -- times‑shown already available
          AND   TO_DATE(r.value:"first_shown"::STRING)    >  '2023-01-01'
          AND   TO_DATE(r.value:"last_shown"::STRING)     <  '2024-01-01'
          -- audience‑selection methods: none may be UNUSED
          AND   COALESCE(PARSE_JSON(c."audience_selection_approach_info"):"contextual_signals"::STRING , 'CRITERIA_UNUSED') <> 'CRITERIA_UNUSED'
          AND   COALESCE(PARSE_JSON(c."audience_selection_approach_info"):"customer_lists"::STRING      , 'CRITERIA_UNUSED') <> 'CRITERIA_UNUSED'
          AND   COALESCE(PARSE_JSON(c."audience_selection_approach_info"):"demographic_info"::STRING    , 'CRITERIA_UNUSED') <> 'CRITERIA_UNUSED'
          AND   COALESCE(PARSE_JSON(c."audience_selection_approach_info"):"geo_location"::STRING        , 'CRITERIA_UNUSED') <> 'CRITERIA_UNUSED'
          AND   COALESCE(PARSE_JSON(c."audience_selection_approach_info"):"topics_of_interest"::STRING  , 'CRITERIA_UNUSED') <> 'CRITERIA_UNUSED'
          AND   r.value:"times_shown_upper_bound"         IS NOT NULL
       )  result
ORDER BY result."times_shown_upper_bound" DESC NULLS LAST,
         result."creative_page_url"
LIMIT 1;