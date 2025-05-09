WITH candidate_ads AS (
    SELECT
        s."creative_page_url",
        /* extract the upper-bound so we can rank later */
        region.value:"times_shown_upper_bound"::NUMBER  AS times_shown_upper_bound
    FROM
        GOOGLE_ADS.GOOGLE_ADS_TRANSPARENCY_CENTER.CREATIVE_STATS  AS s
        ,LATERAL FLATTEN ( INPUT => PARSE_JSON(s."region_stats") ) AS region
    WHERE
        /* ad level filters */
        s."ad_format_type"                    = 'IMAGE'
        AND s."advertiser_verification_status"= 'VERIFIED'
        AND s."advertiser_location"           = 'CY'
        /* keep every targeting dimension in use (none marked UNUSED) */
        AND COALESCE( s."audience_selection_approach_info":"contextual_signals"::STRING , '' ) <> 'CRITERIA_UNUSED'
        AND COALESCE( s."audience_selection_approach_info":"customer_lists"::STRING    , '' ) <> 'CRITERIA_UNUSED'
        AND COALESCE( s."audience_selection_approach_info":"demographic_info"::STRING  , '' ) <> 'CRITERIA_UNUSED'
        AND COALESCE( s."audience_selection_approach_info":"geo_location"::STRING      , '' ) <> 'CRITERIA_UNUSED'
        AND COALESCE( s."audience_selection_approach_info":"topics_of_interest"::STRING, '' ) <> 'CRITERIA_UNUSED'
        /* topic must be Health (case-insensitive match allows slight naming variants) */
        AND LOWER(s."topic") LIKE '%health%'
        /* region-specific filters (Croatia entry) */
        AND region.value:"region_code"::STRING               = 'HR'
        AND region.value:"first_shown"::DATE  > '2023-01-01'
        AND region.value:"last_shown"::DATE   < '2024-01-01'
        /* times_shown data already available => availability date is NULL / absent */
        AND region.value:"times_shown_availability_date" IS NULL
)
SELECT
    "creative_page_url"
FROM
    candidate_ads
ORDER BY
    times_shown_upper_bound DESC NULLS LAST
LIMIT 1;