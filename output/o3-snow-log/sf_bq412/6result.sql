WITH region_ads AS (
    SELECT
        rcs."creative_page_url"                     AS page_url,
        region.value:"first_shown"::date            AS first_shown,
        region.value:"last_shown"::date             AS last_shown,
        region.value:"times_shown_lower_bound"::int AS times_shown_lower_bound,
        region.value:"times_shown_upper_bound"::int AS times_shown_upper_bound,
        dis.value:"removal_reason"::string          AS removal_reason,
        dis.value:"violation_category"::string      AS violation_category
    FROM GOOGLE_ADS.GOOGLE_ADS_TRANSPARENCY_CENTER."REMOVED_CREATIVE_STATS"  rcs
         ,LATERAL FLATTEN(input => rcs."region_stats")                        region
         ,LATERAL FLATTEN(input => rcs."disapproval")                         dis
    WHERE region.value:"region_code"::string = 'HR'
          -- “times_shown_availability_date” must be NULL / absent
          AND region.value:"times_shown_availability_date" IS NULL
          -- impression-range filter
          AND region.value:"times_shown_lower_bound"::int > 10000
          AND region.value:"times_shown_upper_bound"::int < 25000
          -- at least one audience-selection approach not equal to “CRITERIA_UNUSED”
          AND (
                  COALESCE(rcs."audience_selection_approach_info":"demographic_info"::string , 'CRITERIA_UNUSED')        != 'CRITERIA_UNUSED'
               OR COALESCE(rcs."audience_selection_approach_info":"geo_location"::string     , 'CRITERIA_UNUSED')        != 'CRITERIA_UNUSED'
               OR COALESCE(rcs."audience_selection_approach_info":"contextual_signals"::string, 'CRITERIA_UNUSED')       != 'CRITERIA_UNUSED'
               OR COALESCE(rcs."audience_selection_approach_info":"customer_lists"::string   , 'CRITERIA_UNUSED')        != 'CRITERIA_UNUSED'
               OR COALESCE(rcs."audience_selection_approach_info":"topics_of_interest"::string, 'CRITERIA_UNUSED')       != 'CRITERIA_UNUSED'
              )
)
SELECT
    page_url,
    first_shown,
    last_shown,
    removal_reason,
    violation_category,
    times_shown_lower_bound,
    times_shown_upper_bound
FROM region_ads
ORDER BY last_shown DESC NULLS LAST
LIMIT 5;