SELECT
       t."creative_page_url"                                            AS "page_url",
       r.value:"first_shown"::STRING                                    AS "first_shown",
       r.value:"last_shown"::STRING                                     AS "last_shown",
       d.value:"removal_reason"::STRING                                 AS "removal_reason",
       d.value:"violation_category"::STRING                             AS "violation_category",
       r.value:"times_shown_lower_bound"::INTEGER                       AS "times_shown_lower_bound",
       r.value:"times_shown_upper_bound"::INTEGER                       AS "times_shown_upper_bound"
FROM   "GOOGLE_ADS"."GOOGLE_ADS_TRANSPARENCY_CENTER"."REMOVED_CREATIVE_STATS" t
       ,LATERAL FLATTEN(input => t."region_stats")  r
       ,LATERAL FLATTEN(input => t."disapproval")   d
WHERE  r.value:"region_code"::STRING = 'HR'                                              -- Croatia only
  AND  r.value:"times_shown_availability_date" IS NULL                                   -- availability date must be null
  AND  r.value:"times_shown_lower_bound"::INTEGER  > 10000                               -- lower bound > 10 000
  AND  r.value:"times_shown_upper_bound"::INTEGER  < 25000                               -- upper bound < 25 000
  AND (
        t."audience_selection_approach_info":"contextual_signals"::STRING  NOT ILIKE 'CRITERIA_UNUSED'
     OR t."audience_selection_approach_info":"customer_lists"::STRING      NOT ILIKE 'CRITERIA_UNUSED'
     OR t."audience_selection_approach_info":"demographic_info"::STRING    NOT ILIKE 'CRITERIA_UNUSED'
     OR t."audience_selection_approach_info":"geo_location"::STRING        NOT ILIKE 'CRITERIA_UNUSED'
     OR t."audience_selection_approach_info":"topics_of_interest"::STRING  NOT ILIKE 'CRITERIA_UNUSED'
      )                                                                    -- at least one non-unused approach
ORDER BY r.value:"last_shown"::STRING DESC NULLS LAST                      -- most recently removed first
LIMIT 5;