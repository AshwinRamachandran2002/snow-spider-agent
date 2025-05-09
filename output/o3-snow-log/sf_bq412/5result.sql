WITH region_data AS (
    SELECT
        rc."creative_page_url",
        region.value:"first_shown"::DATE                AS first_shown,
        region.value:"last_shown"::DATE                 AS last_shown,
        rc."disapproval"[0]:"removal_reason"::STRING    AS removal_reason,
        rc."disapproval"[0]:"violation_category"::STRING AS violation_category,
        region.value:"times_shown_lower_bound"::NUMBER  AS times_shown_lower_bound,
        region.value:"times_shown_upper_bound"::NUMBER  AS times_shown_upper_bound,
        region.value:"times_shown_availability_date"::DATE AS times_shown_availability_date,
        rc."audience_selection_approach_info"           AS audience_info
    FROM
        GOOGLE_ADS.GOOGLE_ADS_TRANSPARENCY_CENTER.REMOVED_CREATIVE_STATS rc,
        LATERAL FLATTEN(input => rc."region_stats") region
    WHERE
        region.value:"region_code"::STRING = 'HR'
)
SELECT
    "creative_page_url",
    first_shown,
    last_shown,
    removal_reason,
    violation_category,
    times_shown_lower_bound,
    times_shown_upper_bound
FROM
    region_data
WHERE
    times_shown_availability_date IS NULL
    AND times_shown_lower_bound > 10000
    AND times_shown_upper_bound < 25000
    AND (
           COALESCE(audience_info:"contextual_signals"::STRING,  'CRITERIA_UNUSED') != 'CRITERIA_UNUSED'
        OR COALESCE(audience_info:"customer_lists"::STRING,      'CRITERIA_UNUSED') != 'CRITERIA_UNUSED'
        OR COALESCE(audience_info:"demographic_info"::STRING,    'CRITERIA_UNUSED') != 'CRITERIA_UNUSED'
        OR COALESCE(audience_info:"geo_location"::STRING,        'CRITERIA_UNUSED') != 'CRITERIA_UNUSED'
        OR COALESCE(audience_info:"topics_of_interest"::STRING,  'CRITERIA_UNUSED') != 'CRITERIA_UNUSED'
    )
ORDER BY
    last_shown DESC NULLS LAST
LIMIT 5;