SELECT
    r."creative_page_url"                                            AS "creative_page_url",
    reg.value:"first_shown"::date                                    AS "first_shown",
    reg.value:"last_shown"::date                                     AS "last_shown",
    r."disapproval"[0]:"removal_reason"::string                     AS "removal_reason",
    r."disapproval"[0]:"violation_category"::string                 AS "violation_category",
    reg.value:"times_shown_lower_bound"::number                     AS "times_shown_lower_bound",
    reg.value:"times_shown_upper_bound"::number                     AS "times_shown_upper_bound"
FROM
    GOOGLE_ADS.GOOGLE_ADS_TRANSPARENCY_CENTER.REMOVED_CREATIVE_STATS r,
    LATERAL FLATTEN(input => r."region_stats") reg
WHERE
      reg.value:"region_code"::string = 'HR'                                              -- Croatia
  AND reg.value:"times_shown_availability_date" IS NULL                                  -- availability date absent
  AND reg.value:"times_shown_lower_bound"::number  > 10000                               -- lower bound > 10 000
  AND reg.value:"times_shown_upper_bound"::number  < 25000                               -- upper bound < 25 000
  AND (                                                                                  -- at least one non‑unused audience criterion
        COALESCE(r."audience_selection_approach_info":"demographic_info"::string,'CRITERIA_UNUSED')       <> 'CRITERIA_UNUSED'
     OR COALESCE(r."audience_selection_approach_info":"geo_location"::string,'CRITERIA_UNUSED')           <> 'CRITERIA_UNUSED'
     OR COALESCE(r."audience_selection_approach_info":"contextual_signals"::string,'CRITERIA_UNUSED')     <> 'CRITERIA_UNUSED'
     OR COALESCE(r."audience_selection_approach_info":"customer_lists"::string,'CRITERIA_UNUSED')         <> 'CRITERIA_UNUSED'
     OR COALESCE(r."audience_selection_approach_info":"topics_of_interest"::string,'CRITERIA_UNUSED')     <> 'CRITERIA_UNUSED'
      )
ORDER BY
    "last_shown" DESC NULLS LAST
LIMIT 5;