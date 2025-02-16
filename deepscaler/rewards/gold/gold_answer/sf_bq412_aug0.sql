-- Task: Retrieve the 'creative_page_url', 'first_shown', 'last_shown', 'removal_reason', 'violation_category', 'times_shown_lower_bound', and 'times_shown_upper_bound' for the five most recently removed ads in the Croatia region (region code 'HR'), where the 'times_shown_availability_date' is null, the 'times_shown_lower_bound' exceeds 10,000, the 'times_shown_upper_bound' is less than 25,000, and where the ad's 'audience_selection_approach_info' indicates that at least one of 'demographic_info', 'geo_location', 'contextual_signals', 'customer_lists', or 'topics_of_interest' is not 'CRITERIA_UNUSED'. Order the results by 'last_shown' in descending order.
SELECT
    "creative_page_url",
    TO_TIMESTAMP(GET("region_stat".value, 'first_shown')) AS "first_shown",
    TO_TIMESTAMP(GET("region_stat".value, 'last_shown')) AS "last_shown",
    REPLACE(REPLACE("disapproval"[0]."removal_reason", '""', '"'), '"', '') AS "removal_reason", 
    REPLACE(REPLACE("disapproval"[0]."violation_category", '""', '"'), '"', '') AS "violation_category",
    GET("region_stat".value, 'times_shown_lower_bound') AS "times_shown_lower",
    GET("region_stat".value, 'times_shown_upper_bound') AS "times_shown_upper"
FROM
    "GOOGLE_ADS"."GOOGLE_ADS_TRANSPARENCY_CENTER"."REMOVED_CREATIVE_STATS",
    LATERAL FLATTEN(input => "region_stats") AS "region_stat"
WHERE
    GET("region_stat".value, 'region_code') = 'HR' 
    AND GET("region_stat".value, 'times_shown_availability_date') IS NULL 
    AND GET("region_stat".value, 'times_shown_lower_bound') > 10000 
    AND GET("region_stat".value, 'times_shown_upper_bound') < 25000
    AND (
        GET("audience_selection_approach_info", 'demographic_info') != 'CRITERIA_UNUSED' 
        OR GET("audience_selection_approach_info", 'geo_location') != 'CRITERIA_UNUSED' 
        OR GET("audience_selection_approach_info", 'contextual_signals') != 'CRITERIA_UNUSED' 
        OR GET("audience_selection_approach_info", 'customer_lists') != 'CRITERIA_UNUSED' 
        OR GET("audience_selection_approach_info", 'topics_of_interest') != 'CRITERIA_UNUSED'
    )
ORDER BY
    "last_shown" DESC
LIMIT 5;