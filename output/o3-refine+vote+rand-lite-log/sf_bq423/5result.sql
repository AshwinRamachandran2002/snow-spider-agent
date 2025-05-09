WITH expanded AS (
    SELECT
        t."creative_page_url",
        r.value:"times_shown_upper_bound"::NUMBER      AS times_shown_upper_bound
    FROM
        GOOGLE_ADS.GOOGLE_ADS_TRANSPARENCY_CENTER.CREATIVE_STATS t
        ,LATERAL FLATTEN(INPUT => PARSE_JSON(t."region_stats")) r
        ,LATERAL (
            SELECT PARSE_JSON(t."audience_selection_approach_info") AS aud_json
        ) a
    WHERE
        t."ad_format_type" = 'IMAGE'
        AND t."topic" ILIKE '%Health%'
        AND t."advertiser_verification_status" = 'VERIFIED'
        AND t."advertiser_location" = 'CY'
        -- Region‑specific filters
        AND r.value:"region_code"::STRING = 'HR'                     -- Croatia
        AND r.value:"first_shown"::DATE  > DATE '2023-01-01'
        AND r.value:"last_shown"::DATE   < DATE '2024-01-01'
        AND r.value:"times_shown_availability_date" IS NULL          -- times shown data available
        -- Audience‑selection criteria: none may be UNUSED
        AND a.aud_json:"contextual_signals"::STRING      <> 'CRITERIA_UNUSED'
        AND a.aud_json:"customer_lists"::STRING          <> 'CRITERIA_UNUSED'
        AND a.aud_json:"demographic_info"::STRING        <> 'CRITERIA_UNUSED'
        AND a.aud_json:"geo_location"::STRING            <> 'CRITERIA_UNUSED'
        AND a.aud_json:"topics_of_interest"::STRING      <> 'CRITERIA_UNUSED'
)
SELECT "creative_page_url"
FROM   expanded
ORDER BY times_shown_upper_bound DESC NULLS LAST
LIMIT 1;