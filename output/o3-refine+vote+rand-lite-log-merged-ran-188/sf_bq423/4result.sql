WITH candidate_ads AS (
    SELECT  
        cs."creative_page_url",
        cs."creative_id",
        f.value:"times_shown_upper_bound"::INTEGER        AS times_shown_upper_bound
    FROM  GOOGLE_ADS.GOOGLE_ADS_TRANSPARENCY_CENTER."CREATIVE_STATS" cs
          ,LATERAL FLATTEN(INPUT => cs."region_stats") f
    WHERE cs."ad_format_type"               = 'IMAGE'
      AND cs."advertiser_location"          = 'CY'          -- Cyprus
      AND cs."advertiser_verification_status" = 'VERIFIED'
      AND cs."topic" ILIKE '%Health%'                       -- topic of Health
      -- Croatia‑specific region record
      AND f.value:"region_code"::STRING     = 'HR'
      -- Times‑shown statistics already available
      AND f.value:"times_shown_availability_date" IS NULL
      AND f.value:"times_shown_upper_bound" IS NOT NULL
      -- Date window for the HR region
      AND f.value:"first_shown"::DATE  > '2023-01-01'
      AND f.value:"last_shown"::DATE   < '2024-01-01'
      -- All targeting methods are used (none set to CRITERIA_UNUSED)
      AND COALESCE(cs."audience_selection_approach_info":"demographic_info"::STRING          ,'CRITERIA_UNUSED') <> 'CRITERIA_UNUSED'
      AND COALESCE(cs."audience_selection_approach_info":"geo_location"::STRING              ,'CRITERIA_UNUSED') <> 'CRITERIA_UNUSED'
      AND COALESCE(cs."audience_selection_approach_info":"contextual_signals"::STRING        ,'CRITERIA_UNUSED') <> 'CRITERIA_UNUSED'
      AND COALESCE(cs."audience_selection_approach_info":"customer_lists"::STRING            ,'CRITERIA_UNUSED') <> 'CRITERIA_UNUSED'
      AND COALESCE(cs."audience_selection_approach_info":"topics_of_interest"::STRING        ,'CRITERIA_UNUSED') <> 'CRITERIA_UNUSED'
)
SELECT "creative_page_url"
FROM   candidate_ads
QUALIFY ROW_NUMBER() OVER (ORDER BY times_shown_upper_bound DESC NULLS LAST, "creative_id") = 1;