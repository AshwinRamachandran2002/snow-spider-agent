SELECT
    t."creative_page_url" AS "page_url"
FROM
    GOOGLE_ADS.GOOGLE_ADS_TRANSPARENCY_CENTER."CREATIVE_STATS" AS t,
    LATERAL FLATTEN(INPUT => t."region_stats") AS rs
WHERE
    t."ad_format_type" = 'IMAGE'
    AND t."topic" ILIKE '%health%'
    AND t."advertiser_verification_status" = 'VERIFIED'
    AND t."advertiser_location" = 'CY'
    AND rs.value:"region_code"::STRING = 'HR'
    AND rs.value:"times_shown_availability_date" IS NULL
    AND rs.value:"first_shown"::STRING > '2023-01-01'
    AND rs.value:"last_shown"::STRING  < '2024-01-01'
    /* audience‑selection methods must all be present and not 'UNUSED' */
    AND COALESCE(t."audience_selection_approach_info":"demographic_info"::STRING   , 'UNUSED') <> 'UNUSED'
    AND COALESCE(t."audience_selection_approach_info":"geo_location"::STRING      , 'UNUSED') <> 'UNUSED'
    AND COALESCE(t."audience_selection_approach_info":"contextual_signals"::STRING, 'UNUSED') <> 'UNUSED'
    AND COALESCE(t."audience_selection_approach_info":"customer_lists"::STRING    , 'UNUSED') <> 'UNUSED'
    AND COALESCE(t."audience_selection_approach_info":"topics_of_interest"::STRING, 'UNUSED') <> 'UNUSED'
ORDER BY
    rs.value:"times_shown_upper_bound"::NUMBER DESC NULLS LAST,
    t."creative_id"
LIMIT 1;