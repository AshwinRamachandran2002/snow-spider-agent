SELECT DISTINCT t."creative_page_url",
       rs.value:"times_shown_upper_bound"::INTEGER AS "times_shown_upper_bound"
FROM "GOOGLE_ADS"."GOOGLE_ADS_TRANSPARENCY_CENTER"."CREATIVE_STATS" t,
     LATERAL FLATTEN(input => t."region_stats") rs
WHERE t."ad_format_type" = 'IMAGE'
  AND t."advertiser_location" = 'CY'
  AND t."topic" ILIKE '%Health%'
  AND t."advertiser_verification_status" = 'VERIFIED'
  AND rs.value:"region_code"::STRING = 'HR'
  AND rs.value:"first_shown"::DATE >= '2023-01-01'
  AND rs.value:"last_shown"::DATE <= '2024-01-01'
  AND t."audience_selection_approach_info":"demographic_info"::STRING IS NOT NULL
  AND t."audience_selection_approach_info":"geo_location"::STRING IS NOT NULL
  AND t."audience_selection_approach_info":"contextual_signals"::STRING IS NOT NULL
  AND t."audience_selection_approach_info":"customer_lists"::STRING IS NOT NULL
  AND t."audience_selection_approach_info":"topics_of_interest"::STRING IS NOT NULL
ORDER BY "times_shown_upper_bound" DESC NULLS LAST
LIMIT 1;