SELECT
    r."creative_page_url"                                              AS "page_url",
    rs.value:"first_shown"::STRING                                     AS "first_shown_time",
    rs.value:"last_shown"::STRING                                      AS "last_shown_time",
    d.value:"removal_reason"::STRING                                   AS "removal_reason",
    d.value:"violation_category"::STRING                               AS "violation_category",
    rs.value:"times_shown_lower_bound"::INT                            AS "times_shown_lower_bound",
    rs.value:"times_shown_upper_bound"::INT                            AS "times_shown_upper_bound"
FROM
    "GOOGLE_ADS"."GOOGLE_ADS_TRANSPARENCY_CENTER"."REMOVED_CREATIVE_STATS" AS r
    , LATERAL FLATTEN(input => r."region_stats") rs
    , LATERAL FLATTEN(input => r."disapproval")  d
WHERE
    rs.value:"region_code"::STRING = 'HR'
    AND rs.value:"times_shown_availability_date" IS NULL
    AND rs.value:"times_shown_lower_bound"::INT  > 10000
    AND rs.value:"times_shown_upper_bound"::INT  < 25000
    AND (
          COALESCE(r."audience_selection_approach_info":"demographic_info"::STRING , 'CRITERIA_UNUSED') NOT IN ('CRITERIA_UNUSED','CRITERIA_NOT_USED')
       OR COALESCE(r."audience_selection_approach_info":"geo_location"::STRING    , 'CRITERIA_UNUSED') NOT IN ('CRITERIA_UNUSED','CRITERIA_NOT_USED')
       OR COALESCE(r."audience_selection_approach_info":"contextual_signals"::STRING, 'CRITERIA_UNUSED') NOT IN ('CRITERIA_UNUSED','CRITERIA_NOT_USED')
       OR COALESCE(r."audience_selection_approach_info":"customer_lists"::STRING  , 'CRITERIA_UNUSED') NOT IN ('CRITERIA_UNUSED','CRITERIA_NOT_USED')
       OR COALESCE(r."audience_selection_approach_info":"topics_of_interest"::STRING, 'CRITERIA_UNUSED') NOT IN ('CRITERIA_UNUSED','CRITERIA_NOT_USED')
    )
ORDER BY
    rs.value:"last_shown"::DATE DESC NULLS LAST,
    r."creative_page_url"
LIMIT 5;