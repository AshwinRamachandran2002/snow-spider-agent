WITH exploded AS (
    SELECT
        c."creative_id",
        c."creative_page_url",
        r.value                                   AS region_data,
        r.value:"times_shown_upper_bound"::NUMBER AS times_shown_upper_bound
    FROM GOOGLE_ADS.GOOGLE_ADS_TRANSPARENCY_CENTER.CREATIVE_STATS c,
         LATERAL FLATTEN (INPUT => c."region_stats") r
    WHERE
          /* ad‑level requirements */
          c."ad_format_type"                 = 'IMAGE'
      AND c."topic"                          ILIKE '%Health%'          -- topic “Health”
      AND c."advertiser_verification_status" = 'VERIFIED'
      AND c."advertiser_location"            = 'CY'                    -- Cyprus
          /* audience‑selection must NOT be unused */
      AND c."audience_selection_approach_info":"contextual_signals"::STRING  <> 'CRITERIA_UNUSED'
      AND c."audience_selection_approach_info":"customer_lists"::STRING      <> 'CRITERIA_UNUSED'
      AND c."audience_selection_approach_info":"demographic_info"::STRING    <> 'CRITERIA_UNUSED'
      AND c."audience_selection_approach_info":"geo_location"::STRING        <> 'CRITERIA_UNUSED'
      AND c."audience_selection_approach_info":"topics_of_interest"::STRING  <> 'CRITERIA_UNUSED'
          /* region‑level requirements (Croatia, dates, availability) */
      AND r.value:"region_code"::STRING           = 'HR'               -- Croatia
      AND r.value:"first_shown"::DATE  > '2023-01-01'
      AND r.value:"last_shown" ::DATE  < '2024-01-01'
      AND r.value:"times_shown_availability_date" IS NULL              -- times shown already available
)
SELECT "creative_page_url"
FROM   exploded
ORDER  BY times_shown_upper_bound DESC NULLS LAST,               -- pick highest upper bound
          "creative_id"
LIMIT  1;