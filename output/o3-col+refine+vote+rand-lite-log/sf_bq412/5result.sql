SELECT
    t."creative_page_url"                                        AS "page_url",
    r.value:"first_shown"::DATE                                  AS "first_shown",
    r.value:"last_shown"::DATE                                   AS "last_shown",
    d.value:"removal_reason"::STRING                             AS "removal_reason",
    d.value:"violation_category"::STRING                         AS "violation_category",
    r.value:"times_shown_lower_bound"::NUMBER                    AS "lower_bound",
    r.value:"times_shown_upper_bound"::NUMBER                    AS "upper_bound"
FROM "GOOGLE_ADS"."GOOGLE_ADS_TRANSPARENCY_CENTER"."REMOVED_CREATIVE_STATS" t
     , LATERAL FLATTEN(input => t."region_stats")  r
     , LATERAL FLATTEN(input => t."disapproval")   d
WHERE r.value:"region_code"::STRING = 'HR'
  AND r.value:"times_shown_availability_date" IS NULL
  AND r.value:"times_shown_lower_bound"::NUMBER > 10000
  AND r.value:"times_shown_upper_bound"::NUMBER < 25000
  AND (
        COALESCE(t."audience_selection_approach_info":"contextual_signals"::STRING , 'CRITERIA_UNUSED') <> 'CRITERIA_UNUSED'
     OR COALESCE(t."audience_selection_approach_info":"customer_lists"::STRING      , 'CRITERIA_UNUSED') <> 'CRITERIA_UNUSED'
     OR COALESCE(t."audience_selection_approach_info":"demographic_info"::STRING    , 'CRITERIA_UNUSED') <> 'CRITERIA_UNUSED'
     OR COALESCE(t."audience_selection_approach_info":"geo_location"::STRING        , 'CRITERIA_UNUSED') <> 'CRITERIA_UNUSED'
     OR COALESCE(t."audience_selection_approach_info":"topics_of_interest"::STRING  , 'CRITERIA_UNUSED') <> 'CRITERIA_UNUSED'
      )
QUALIFY ROW_NUMBER() OVER (PARTITION BY t."creative_page_url" ORDER BY d.index) = 1   -- keep one row per ad
ORDER BY "last_shown" DESC NULLS LAST
LIMIT 5;