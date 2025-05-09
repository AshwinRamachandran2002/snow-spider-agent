SELECT      t."creative_page_url"
FROM        GOOGLE_ADS.GOOGLE_ADS_TRANSPARENCY_CENTER.CREATIVE_STATS  AS t,
            LATERAL FLATTEN (INPUT => t."region_stats")               AS s
WHERE       t."ad_format_type"                     = 'IMAGE'
    AND     t."advertiser_location"                = 'CY'
    AND     t."advertiser_verification_status"     = 'VERIFIED'
    AND     t."topic" ILIKE '%health%'
    -- every audience-selection method must be used (≠ 'CRITERIA_UNUSED')
    AND     t."audience_selection_approach_info":"contextual_signals"::STRING  <> 'CRITERIA_UNUSED'
    AND     t."audience_selection_approach_info":"customer_lists"::STRING      <> 'CRITERIA_UNUSED'
    AND     t."audience_selection_approach_info":"demographic_info"::STRING    <> 'CRITERIA_UNUSED'
    AND     t."audience_selection_approach_info":"geo_location"::STRING        <> 'CRITERIA_UNUSED'
    AND     t."audience_selection_approach_info":"topics_of_interest"::STRING   <> 'CRITERIA_UNUSED'
    -- Croatia region, 2023 calendar window, and times-shown data already available
    AND     s.value:"region_code"::STRING                = 'HR'
    AND     s.value:"first_shown"::DATE   >  '2023-01-01'
    AND     s.value:"last_shown"::DATE    <  '2024-01-01'
    AND     s.value:"times_shown_availability_date" IS NULL
GROUP BY    t."creative_page_url"
ORDER BY    MAX(s.value:"times_shown_upper_bound"::NUMBER) DESC NULLS LAST
LIMIT 1;