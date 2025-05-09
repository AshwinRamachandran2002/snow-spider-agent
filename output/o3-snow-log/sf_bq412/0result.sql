WITH filtered AS (
    SELECT
        r."creative_page_url"                                            AS "creative_page_url",
        rs.value:"first_shown"::DATE                                     AS "first_shown",
        rs.value:"last_shown"::DATE                                      AS "last_shown",
        r."disapproval"[0]:"removal_reason"::STRING                     AS "removal_reason",
        r."disapproval"[0]:"violation_category"::STRING                 AS "violation_category",
        rs.value:"times_shown_lower_bound"::NUMBER                      AS "times_shown_lower_bound",
        rs.value:"times_shown_upper_bound"::NUMBER                      AS "times_shown_upper_bound"
    FROM
        GOOGLE_ADS.GOOGLE_ADS_TRANSPARENCY_CENTER.REMOVED_CREATIVE_STATS r,
        LATERAL FLATTEN ( input => r."region_stats" ) rs
    WHERE
            rs.value:"region_code"::STRING = 'HR'                                    -- Croatia
        AND rs.value:"times_shown_lower_bound"::NUMBER > 10000
        AND rs.value:"times_shown_upper_bound"::NUMBER < 25000
        AND rs.value:"times_shown_availability_date" IS NULL
        AND (
                COALESCE( r."audience_selection_approach_info":"contextual_signals"::STRING , 'CRITERIA_UNUSED' ) <> 'CRITERIA_UNUSED'
             OR COALESCE( r."audience_selection_approach_info":"customer_lists"::STRING     , 'CRITERIA_UNUSED' ) <> 'CRITERIA_UNUSED'
             OR COALESCE( r."audience_selection_approach_info":"demographic_info"::STRING   , 'CRITERIA_UNUSED' ) <> 'CRITERIA_UNUSED'
             OR COALESCE( r."audience_selection_approach_info":"geo_location"::STRING       , 'CRITERIA_UNUSED' ) <> 'CRITERIA_UNUSED'
             OR COALESCE( r."audience_selection_approach_info":"topics_of_interest"::STRING , 'CRITERIA_UNUSED' ) <> 'CRITERIA_UNUSED'
            )
)
SELECT *
FROM   filtered
ORDER  BY "last_shown" DESC NULLS LAST
LIMIT 5;