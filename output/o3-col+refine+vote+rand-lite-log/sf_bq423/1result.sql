WITH hr_ads AS (
    SELECT
        t."creative_page_url",
        f.value:"times_shown_upper_bound"::INTEGER         AS upper_bound
    FROM "GOOGLE_ADS"."GOOGLE_ADS_TRANSPARENCY_CENTER"."CREATIVE_STATS"  t,
         LATERAL FLATTEN (INPUT => t."region_stats")                      f
    WHERE  t."ad_format_type"               = 'IMAGE'
      AND  t."advertiser_location"          = 'CY'
      AND  t."advertiser_verification_status" = 'VERIFIED'
      AND  t."topic" ILIKE '%Health%'
      -- every audience–selection method is present and NOT UNUSED
      AND  COALESCE(t."audience_selection_approach_info":"demographic_info"::STRING , 'CRITERIA_UNUSED')      <> 'CRITERIA_UNUSED'
      AND  COALESCE(t."audience_selection_approach_info":"geo_location"::STRING      , 'CRITERIA_UNUSED')      <> 'CRITERIA_UNUSED'
      AND  COALESCE(t."audience_selection_approach_info":"contextual_signals"::STRING, 'CRITERIA_UNUSED')      <> 'CRITERIA_UNUSED'
      AND  COALESCE(t."audience_selection_approach_info":"customer_lists"::STRING    , 'CRITERIA_UNUSED')      <> 'CRITERIA_UNUSED'
      AND  COALESCE(t."audience_selection_approach_info":"topics_of_interest"::STRING, 'CRITERIA_UNUSED')      <> 'CRITERIA_UNUSED'
      -- Croatia-specific stats within the required date window
      AND  f.value:"region_code"::STRING      = 'HR'
      AND  f.value:"first_shown"::STRING  >  '2023-01-01'
      AND  f.value:"last_shown"::STRING   <  '2024-01-01'
      -- times shown data already available
      AND  f.value:"times_shown_availability_date" IS NULL
)
SELECT "creative_page_url"
FROM   hr_ads
ORDER  BY upper_bound DESC NULLS LAST
LIMIT  1;