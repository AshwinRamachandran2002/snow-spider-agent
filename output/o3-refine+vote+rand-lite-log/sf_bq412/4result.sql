WITH HR_ADS AS (
    SELECT
        r.value:"first_shown"::DATE               AS "first_shown",
        r.value:"last_shown"::DATE                AS "last_shown",
        r.value:"times_shown_lower_bound"::NUMBER AS "times_shown_lower_bound",
        r.value:"times_shown_upper_bound"::NUMBER AS "times_shown_upper_bound",
        rc."creative_page_url"                    AS "page_url",
        rc."audience_selection_approach_info"     AS "audience_info",
        d.value:"removal_reason"::STRING          AS "removal_reason",
        d.value:"violation_category"::STRING      AS "violation_category"
    FROM
        GOOGLE_ADS.GOOGLE_ADS_TRANSPARENCY_CENTER."REMOVED_CREATIVE_STATS" rc,
        LATERAL FLATTEN(input => rc."region_stats")      r,
        LATERAL FLATTEN(input => rc."disapproval")       d
    WHERE
          r.value:"region_code"::STRING = 'HR'                       -- Croatia only
      AND r.value:"times_shown_availability_date" IS NULL            -- availability date must be NULL / absent
      AND r.value:"times_shown_lower_bound"::NUMBER  > 10000         -- lower bound > 10 000
      AND r.value:"times_shown_upper_bound"::NUMBER  < 25000         -- upper bound < 25 000
)
SELECT
    "page_url",
    "first_shown",
    "last_shown",
    "removal_reason",
    "violation_category",
    "times_shown_lower_bound",
    "times_shown_upper_bound"
FROM HR_ADS
/* keep rows where at least one audience‑selection dimension is NOT “CRITERIA_UNUSED” */
WHERE
      COALESCE("audience_info":"contextual_signals"::STRING , 'CRITERIA_UNUSED') <> 'CRITERIA_UNUSED'
   OR COALESCE("audience_info":"customer_lists"::STRING    , 'CRITERIA_UNUSED') <> 'CRITERIA_UNUSED'
   OR COALESCE("audience_info":"demographic_info"::STRING  , 'CRITERIA_UNUSED') <> 'CRITERIA_UNUSED'
   OR COALESCE("audience_info":"geo_location"::STRING      , 'CRITERIA_UNUSED') <> 'CRITERIA_UNUSED'
   OR COALESCE("audience_info":"topics_of_interest"::STRING, 'CRITERIA_UNUSED') <> 'CRITERIA_UNUSED'
/* if a creative appears multiple times (e.g. multiple disapproval rows), keep the most‑recent one */
QUALIFY ROW_NUMBER() OVER (PARTITION BY "page_url" ORDER BY "last_shown" DESC) = 1
ORDER BY
    "last_shown" DESC NULLS LAST
LIMIT 5;