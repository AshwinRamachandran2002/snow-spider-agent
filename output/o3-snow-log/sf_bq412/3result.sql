WITH region_level AS (
    SELECT
        rcs."creative_page_url",
        region.value:"first_shown"::DATE        AS "first_shown",
        region.value:"last_shown"::DATE         AS "last_shown",
        region.value:"times_shown_lower_bound"::NUMBER AS "times_shown_lower_bound",
        region.value:"times_shown_upper_bound"::NUMBER AS "times_shown_upper_bound",
        dis.value:"removal_reason"::STRING      AS "removal_reason",
        dis.value:"violation_category"::STRING  AS "violation_category",
        rcs."audience_selection_approach_info"  AS audience_info
    FROM  GOOGLE_ADS.GOOGLE_ADS_TRANSPARENCY_CENTER.REMOVED_CREATIVE_STATS  rcs,
          LATERAL FLATTEN(input => rcs."region_stats")                      region,
          LATERAL FLATTEN(input => rcs."disapproval")                       dis
    WHERE region.value:"region_code"::STRING = 'HR'                              -- Croatia only
      AND region.value:"times_shown_lower_bound"::NUMBER > 10000                 -- lower-bound filter
      AND region.value:"times_shown_upper_bound"::NUMBER < 25000                 -- upper-bound filter
      AND region.value:"times_shown_availability_date" IS NULL                  -- availability date must be NULL / not present
      -- at least one audience-selection approach ≠ CRITERIA_UNUSED
      AND (
            COALESCE(audience_info:"demographic_info"::STRING,      'CRITERIA_UNUSED') <> 'CRITERIA_UNUSED' OR
            COALESCE(audience_info:"geo_location"::STRING,          'CRITERIA_UNUSED') <> 'CRITERIA_UNUSED' OR
            COALESCE(audience_info:"contextual_signals"::STRING,    'CRITERIA_UNUSED') <> 'CRITERIA_UNUSED' OR
            COALESCE(audience_info:"customer_lists"::STRING,        'CRITERIA_UNUSED') <> 'CRITERIA_UNUSED' OR
            COALESCE(audience_info:"topics_of_interest"::STRING,    'CRITERIA_UNUSED') <> 'CRITERIA_UNUSED'
          )
)
SELECT
    "creative_page_url",
    "first_shown",
    "last_shown",
    "removal_reason",
    "violation_category",
    "times_shown_lower_bound",
    "times_shown_upper_bound"
FROM   region_level
QUALIFY ROW_NUMBER() OVER (PARTITION BY "creative_page_url" ORDER BY "last_shown" DESC) = 1   -- one row per creative
ORDER  BY "last_shown" DESC NULLS LAST
LIMIT 5;