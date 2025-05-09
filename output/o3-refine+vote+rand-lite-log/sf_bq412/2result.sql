SELECT
    t."creative_page_url"                                                  AS "page_url",
    region.value:first_shown::DATE                                         AS "first_shown",
    region.value:last_shown::DATE                                          AS "last_shown",
    t."disapproval"[0]:removal_reason::STRING                              AS "removal_reason",
    t."disapproval"[0]:violation_category::STRING                          AS "violation_category",
    region.value:times_shown_lower_bound::NUMBER                           AS "times_shown_lower_bound",
    region.value:times_shown_upper_bound::NUMBER                           AS "times_shown_upper_bound"
FROM GOOGLE_ADS.GOOGLE_ADS_TRANSPARENCY_CENTER.REMOVED_CREATIVE_STATS t,
     LATERAL FLATTEN(input => t."region_stats") region
WHERE region.value:region_code::STRING = 'HR'
  AND region.value:times_shown_availability_date IS NULL
  AND region.value:times_shown_lower_bound::NUMBER > 10000
  AND region.value:times_shown_upper_bound::NUMBER < 25000
  AND (
        COALESCE(t."audience_selection_approach_info":demographic_info::STRING,   'CRITERIA_UNUSED') != 'CRITERIA_UNUSED'
     OR COALESCE(t."audience_selection_approach_info":geo_location::STRING,       'CRITERIA_UNUSED') != 'CRITERIA_UNUSED'
     OR COALESCE(t."audience_selection_approach_info":contextual_signals::STRING, 'CRITERIA_UNUSED') != 'CRITERIA_UNUSED'
     OR COALESCE(t."audience_selection_approach_info":customer_lists::STRING,     'CRITERIA_UNUSED') != 'CRITERIA_UNUSED'
     OR COALESCE(t."audience_selection_approach_info":topics_of_interest::STRING, 'CRITERIA_UNUSED') != 'CRITERIA_UNUSED'
      )
ORDER BY "last_shown" DESC NULLS LAST
LIMIT 5;