WITH candidate_ads AS (
    SELECT
        cs."creative_page_url",
        rs.value:"times_shown_upper_bound"::NUMBER AS "times_shown_upper_bound"
    FROM  GOOGLE_ADS.GOOGLE_ADS_TRANSPARENCY_CENTER.CREATIVE_STATS cs,
          LATERAL FLATTEN(INPUT => cs."region_stats")                           rs,
          LATERAL FLATTEN(INPUT => ARRAY_CONSTRUCT(cs."audience_selection_approach_info")) asi
    WHERE cs."ad_format_type"                 = 'IMAGE'
      AND cs."topic"                          ILIKE '%Health%'
      AND cs."advertiser_location"            = 'CY'
      AND cs."advertiser_verification_status" = 'VERIFIED'
      AND rs.value:"region_code"::STRING      = 'HR'
      AND rs.value:"times_shown_availability_date" IS NULL
      AND rs.value:"first_shown"::DATE  > '2023-01-01'
      AND rs.value:"last_shown" ::DATE  < '2024-01-01'
      AND asi.value:"contextual_signals" ::STRING <> 'CRITERIA_UNUSED'
      AND asi.value:"customer_lists"      ::STRING <> 'CRITERIA_UNUSED'
      AND asi.value:"demographic_info"    ::STRING <> 'CRITERIA_UNUSED'
      AND asi.value:"geo_location"        ::STRING <> 'CRITERIA_UNUSED'
      AND asi.value:"topics_of_interest"  ::STRING <> 'CRITERIA_UNUSED'
)
SELECT  ca."creative_page_url"
FROM   (
        SELECT  "creative_page_url",
                MAX("times_shown_upper_bound") AS "max_upper_bound"
        FROM    candidate_ads
        GROUP BY "creative_page_url"
       ) ca
ORDER BY ca."max_upper_bound" DESC NULLS LAST
LIMIT 1;