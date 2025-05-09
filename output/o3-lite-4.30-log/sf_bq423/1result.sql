SELECT "creative_page_url" AS page_url
FROM (
    SELECT
        t."creative_page_url",
        r.value:"times_shown_upper_bound"::NUMBER AS times_shown_upper_bound
    FROM GOOGLE_ADS.GOOGLE_ADS_TRANSPARENCY_CENTER.CREATIVE_STATS t,
         LATERAL FLATTEN(input => t."region_stats"::VARIANT) r
    WHERE
          t."ad_format_type" = 'IMAGE'
      AND t."topic" ILIKE '%health%'
      AND t."advertiser_verification_status" = 'VERIFIED'
      AND t."advertiser_location" = 'CY'
      -- Croatia impressions
      AND r.value:"region_code"::STRING = 'HR'
      AND r.value:"first_shown"::DATE > '2023-01-01'
      AND r.value:"last_shown" ::DATE < '2024-01-01'
      AND r.value:"times_shown_availability_date" IS NULL
      -- Targeting methods must all be present and not UNUSED
      AND t."audience_selection_approach_info":"demographic_info"       IS NOT NULL
      AND UPPER(t."audience_selection_approach_info":"demographic_info"::STRING)      <> 'UNUSED'
      AND t."audience_selection_approach_info":"geo_location"           IS NOT NULL
      AND UPPER(t."audience_selection_approach_info":"geo_location"::STRING)          <> 'UNUSED'
      AND t."audience_selection_approach_info":"contextual_signals"     IS NOT NULL
      AND UPPER(t."audience_selection_approach_info":"contextual_signals"::STRING)    <> 'UNUSED'
      AND t."audience_selection_approach_info":"customer_lists"         IS NOT NULL
      AND UPPER(t."audience_selection_approach_info":"customer_lists"::STRING)        <> 'UNUSED'
      AND t."audience_selection_approach_info":"topics_of_interest"     IS NOT NULL
      AND UPPER(t."audience_selection_approach_info":"topics_of_interest"::STRING)    <> 'UNUSED'
) q
ORDER BY times_shown_upper_bound DESC NULLS LAST, page_url
LIMIT 1;