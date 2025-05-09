WITH exploded AS (
    SELECT
        r."creative_page_url",
        rs.value:first_shown::DATE                     AS "first_shown",
        rs.value:last_shown::DATE                      AS "last_shown",
        rs.value:times_shown_lower_bound::NUMBER       AS "times_shown_lower_bound",
        rs.value:times_shown_upper_bound::NUMBER       AS "times_shown_upper_bound",
        rs.value:times_shown_availability_date         AS "times_shown_availability_date",
        r."disapproval"[0]:"removal_reason"::STRING    AS "removal_reason",
        r."disapproval"[0]:"violation_category"::STRING AS "violation_category",
        r."audience_selection_approach_info":contextual_signals::STRING  AS "contextual_signals",
        r."audience_selection_approach_info":customer_lists::STRING      AS "customer_lists",
        r."audience_selection_approach_info":demographic_info::STRING    AS "demographic_info",
        r."audience_selection_approach_info":geo_location::STRING        AS "geo_location",
        r."audience_selection_approach_info":topics_of_interest::STRING  AS "topics_of_interest"
    FROM
        GOOGLE_ADS.GOOGLE_ADS_TRANSPARENCY_CENTER.REMOVED_CREATIVE_STATS r,
        LATERAL FLATTEN(INPUT => r."region_stats") rs
    WHERE
        rs.value:region_code::STRING = 'HR'                      -- Croatia
)

SELECT
    "creative_page_url",
    "first_shown",
    "last_shown",
    "removal_reason",
    "violation_category",
    "times_shown_lower_bound",
    "times_shown_upper_bound"
FROM
    exploded
WHERE
        "times_shown_availability_date" IS NULL                  -- availability date must be null
    AND "times_shown_lower_bound"  > 10000                       -- > 10 000
    AND "times_shown_upper_bound"  < 25000                       -- < 25 000
    AND (                                                         -- at least one audience criterion not UNUSED
           COALESCE("contextual_signals" ,'CRITERIA_UNUSED')    <> 'CRITERIA_UNUSED'
        OR COALESCE("customer_lists"    ,'CRITERIA_UNUSED')    <> 'CRITERIA_UNUSED'
        OR COALESCE("demographic_info"  ,'CRITERIA_UNUSED')    <> 'CRITERIA_UNUSED'
        OR COALESCE("geo_location"      ,'CRITERIA_UNUSED')    <> 'CRITERIA_UNUSED'
        OR COALESCE("topics_of_interest",'CRITERIA_UNUSED')    <> 'CRITERIA_UNUSED'
    )
ORDER BY
    "last_shown" DESC NULLS LAST
LIMIT 5;