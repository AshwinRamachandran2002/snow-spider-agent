SELECT
       t."creative_page_url"                                               AS "creative_page_url",
       r.value:"first_shown"::STRING                                       AS "first_shown",
       r.value:"last_shown"::STRING                                        AS "last_shown",
       d.value:"removal_reason"::STRING                                    AS "removal_reason",
       d.value:"violation_category"::STRING                                AS "violation_category",
       r.value:"times_shown_lower_bound"::NUMBER                           AS "times_shown_lower_bound",
       r.value:"times_shown_upper_bound"::NUMBER                           AS "times_shown_upper_bound"
FROM   "GOOGLE_ADS"."GOOGLE_ADS_TRANSPARENCY_CENTER"."REMOVED_CREATIVE_STATS" t,
       LATERAL FLATTEN( INPUT => t."region_stats")                     r,
       LATERAL FLATTEN( INPUT => t."audience_selection_approach_info") a,
       LATERAL FLATTEN( INPUT => t."disapproval")                      d
WHERE  r.value:"region_code"::STRING                         = 'HR'
  AND  r.value:"times_shown_availability_date"               IS NULL
  AND  r.value:"times_shown_lower_bound"::NUMBER             > 10000
  AND  r.value:"times_shown_upper_bound"::NUMBER             < 25000
  AND  a.key::STRING IN ( 'demographic_info',
                          'geo_location',
                          'contextual_signals',
                          'customer_lists',
                          'topics_of_interest')
  AND  a.value::STRING NOT ILIKE 'CRITERIA_UNUSED'
QUALIFY ROW_NUMBER() OVER (PARTITION BY t."creative_page_url"
                           ORDER BY r.value:"last_shown"::DATE DESC) = 1
ORDER BY r.value:"last_shown"::DATE DESC NULLS LAST
LIMIT 5;