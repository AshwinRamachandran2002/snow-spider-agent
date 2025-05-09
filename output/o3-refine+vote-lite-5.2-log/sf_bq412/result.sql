WITH hr_removed_ads AS (
    SELECT
        r."creative_page_url"                                             AS "creative_page_url",
        region.value:"first_shown"::DATE                                   AS "first_shown",
        region.value:"last_shown"::DATE                                    AS "last_shown",
        dis.value:"removal_reason"::STRING                                 AS "removal_reason",
        dis.value:"violation_category"::STRING                             AS "violation_category",
        region.value:"times_shown_lower_bound"::NUMBER                     AS "times_shown_lower_bound",
        region.value:"times_shown_upper_bound"::NUMBER                     AS "times_shown_upper_bound"
    FROM GOOGLE_ADS.GOOGLE_ADS_TRANSPARENCY_CENTER.REMOVED_CREATIVE_STATS r
         , LATERAL FLATTEN(input => r."region_stats")  region
         , LATERAL FLATTEN(input => r."disapproval")    dis
    WHERE region.value:"region_code"::STRING = 'HR'                                              -- Croatia
      AND region.value:"times_shown_availability_date" IS NULL                                   -- availability date must be null
      AND region.value:"times_shown_lower_bound"::NUMBER > 10000                                 -- lower‑bound filter
      AND region.value:"times_shown_upper_bound"::NUMBER < 25000                                 -- upper‑bound filter
      /* at least one audience‑selection approach is NOT “CRITERIA_UNUSED” */
      AND (
              COALESCE(r."audience_selection_approach_info":"contextual_signals"::STRING, 'CRITERIA_UNUSED')          <> 'CRITERIA_UNUSED'
           OR COALESCE(r."audience_selection_approach_info":"customer_lists"::STRING,        'CRITERIA_UNUSED')        <> 'CRITERIA_UNUSED'
           OR COALESCE(r."audience_selection_approach_info":"demographic_info"::STRING,      'CRITERIA_UNUSED')        <> 'CRITERIA_UNUSED'
           OR COALESCE(r."audience_selection_approach_info":"geo_location"::STRING,          'CRITERIA_UNUSED')        <> 'CRITERIA_UNUSED'
           OR COALESCE(r."audience_selection_approach_info":"topics_of_interest"::STRING,    'CRITERIA_UNUSED')        <> 'CRITERIA_UNUSED'
          )
      AND dis.index = 0   -- use the first disapproval entry per ad
)
SELECT
    "creative_page_url",
    "first_shown",
    "last_shown",
    "removal_reason",
    "violation_category",
    "times_shown_lower_bound",
    "times_shown_upper_bound"
FROM hr_removed_ads
ORDER BY "last_shown" DESC NULLS LAST
LIMIT 5;