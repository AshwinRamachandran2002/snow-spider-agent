WITH hr_removed AS (
    SELECT
        rc."creative_page_url",
        region.value:"first_shown"::DATE          AS first_shown,
        region.value:"last_shown"::DATE           AS last_shown,
        disapproval.value:"removal_reason"::TEXT  AS removal_reason,
        disapproval.value:"violation_category"::TEXT AS violation_category,
        region.value:"times_shown_lower_bound"::NUMBER AS times_shown_lower_bound,
        region.value:"times_shown_upper_bound"::NUMBER AS times_shown_upper_bound,
        ROW_NUMBER() OVER (
            PARTITION BY rc."creative_page_url"
            ORDER BY region.value:"last_shown"::DATE DESC, disapproval.index
        ) AS rn
    FROM GOOGLE_ADS.GOOGLE_ADS_TRANSPARENCY_CENTER."REMOVED_CREATIVE_STATS" rc
         , LATERAL FLATTEN(input => rc."region_stats")  region
         , LATERAL FLATTEN(input => rc."disapproval")   disapproval
    WHERE region.value:"region_code"::TEXT = 'HR'
      AND region.value:"times_shown_lower_bound"::NUMBER > 10000
      AND region.value:"times_shown_upper_bound"::NUMBER < 25000
      AND region.value:"times_shown_availability_date" IS NULL
      AND (
             rc."audience_selection_approach_info":"contextual_signals"::TEXT      != 'CRITERIA_UNUSED'
          OR rc."audience_selection_approach_info":"customer_lists"::TEXT          != 'CRITERIA_UNUSED'
          OR rc."audience_selection_approach_info":"demographic_info"::TEXT        != 'CRITERIA_UNUSED'
          OR rc."audience_selection_approach_info":"geo_location"::TEXT            != 'CRITERIA_UNUSED'
          OR rc."audience_selection_approach_info":"topics_of_interest"::TEXT      != 'CRITERIA_UNUSED'
      )
)
SELECT
    "creative_page_url",
    first_shown,
    last_shown,
    removal_reason,
    violation_category,
    times_shown_lower_bound,
    times_shown_upper_bound
FROM hr_removed
WHERE rn = 1
ORDER BY last_shown DESC NULLS LAST, "creative_page_url"
LIMIT 5;