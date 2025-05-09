SELECT
    c."creative_page_url"
FROM  GOOGLE_ADS.GOOGLE_ADS_TRANSPARENCY_CENTER.CREATIVE_STATS c,
      LATERAL FLATTEN(INPUT => c."region_stats") r
WHERE c."ad_format_type" = 'IMAGE'
  AND c."advertiser_location" = 'CY'
  AND c."advertiser_verification_status" = 'VERIFIED'
  AND c."topic" ILIKE '%Health%'
  AND r.value:"region_code"::STRING = 'HR'
  AND r.value:"first_shown"::DATE  > '2023-01-01'
  AND r.value:"last_shown"::DATE   < '2024-01-01'
  AND r.value:"times_shown_availability_date" IS NULL
  AND c."audience_selection_approach_info":"contextual_signals"::STRING <> 'CRITERIA_UNUSED'
  AND c."audience_selection_approach_info":"customer_lists"::STRING     <> 'CRITERIA_UNUSED'
  AND c."audience_selection_approach_info":"demographic_info"::STRING   <> 'CRITERIA_UNUSED'
  AND c."audience_selection_approach_info":"geo_location"::STRING       <> 'CRITERIA_UNUSED'
  AND c."audience_selection_approach_info":"topics_of_interest"::STRING <> 'CRITERIA_UNUSED'
ORDER BY r.value:"times_shown_upper_bound"::INTEGER DESC NULLS LAST
LIMIT 1;