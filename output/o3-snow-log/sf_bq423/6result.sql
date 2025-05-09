/* Ad on the topic “Health”, IMAGE type, verified Cypriot advertiser,
   served in Croatia (HR) with available “times shown” data
   and using all five audience–selection methods (none “CRITERIA_UNUSED”).
   Return the URL of the ad that reached the highest upper-bound
   impression count between 2023-01-02 and 2023-12-31. */

SELECT
    cs."creative_page_url"
FROM
    GOOGLE_ADS.GOOGLE_ADS_TRANSPARENCY_CENTER.CREATIVE_STATS   cs,
    LATERAL FLATTEN( INPUT => cs."region_stats" )              rs
WHERE
        -------------------------------------------------------
        -- region-level filters (Croatia statistics only)
        -------------------------------------------------------
        rs.value:"region_code"::STRING = 'HR'
    AND rs.value:"times_shown_availability_date" IS NULL                -- times shown data already available
    AND rs.value:"first_shown"::DATE  >  '2023-01-01'                   -- strictly after 2023-01-01
    AND rs.value:"last_shown" ::DATE  <  '2024-01-01'                   -- strictly before 2024-01-01
        -------------------------------------------------------
        -- creative-level filters
        -------------------------------------------------------
    AND cs."ad_format_type"             = 'IMAGE'
    AND cs."topic"                      = 'Health'
    AND cs."advertiser_verification_status" = 'VERIFIED'
    AND cs."advertiser_location"        = 'CY'
        -------------------------------------------------------
        -- audience-selection requirements (none “CRITERIA_UNUSED”)
        -------------------------------------------------------
    AND cs."audience_selection_approach_info":"demographic_info"::STRING      != 'CRITERIA_UNUSED'
    AND cs."audience_selection_approach_info":"geo_location"::STRING          != 'CRITERIA_UNUSED'
    AND cs."audience_selection_approach_info":"contextual_signals"::STRING    != 'CRITERIA_UNUSED'
    AND cs."audience_selection_approach_info":"customer_lists"::STRING        != 'CRITERIA_UNUSED'
    AND cs."audience_selection_approach_info":"topics_of_interest"::STRING    != 'CRITERIA_UNUSED'
ORDER BY
    rs.value:"times_shown_upper_bound"::NUMBER DESC NULLS LAST        -- highest upper-bound impressions first
LIMIT 1;