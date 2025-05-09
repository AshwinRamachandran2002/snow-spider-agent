SELECT
    cs."creative_page_url"
FROM "GOOGLE_ADS"."GOOGLE_ADS_TRANSPARENCY_CENTER"."CREATIVE_STATS" cs,
     LATERAL FLATTEN(input => cs."region_stats") rs
WHERE cs."ad_format_type" = 'IMAGE'
  AND cs."advertiser_location" = 'CY'
  AND cs."advertiser_verification_status" = 'VERIFIED'
  AND cs."topic" ILIKE '%Health%'
  /* every targeting method must be used (not 'CRITERIA_UNUSED' and not NULL) */
  AND COALESCE(cs."audience_selection_approach_info":"demographic_info"::STRING , 'CRITERIA_UNUSED')        != 'CRITERIA_UNUSED'
  AND COALESCE(cs."audience_selection_approach_info":"geo_location"::STRING     , 'CRITERIA_UNUSED')        != 'CRITERIA_UNUSED'
  AND COALESCE(cs."audience_selection_approach_info":"contextual_signals"::STRING, 'CRITERIA_UNUSED')        != 'CRITERIA_UNUSED'
  AND COALESCE(cs."audience_selection_approach_info":"customer_lists"::STRING    , 'CRITERIA_UNUSED')        != 'CRITERIA_UNUSED'
  AND COALESCE(cs."audience_selection_approach_info":"topics_of_interest"::STRING, 'CRITERIA_UNUSED')        != 'CRITERIA_UNUSED'
  /* Croatia-specific stats in the required date window and with available times-shown data */
  AND rs.value:"region_code"::STRING              = 'HR'
  AND rs.value:"first_shown"::DATE               > '2023-01-01'
  AND rs.value:"last_shown"::DATE                < '2024-01-01'
  AND rs.value:"times_shown_availability_date" IS NULL
ORDER BY rs.value:"times_shown_upper_bound"::NUMBER DESC NULLS LAST
LIMIT 1;