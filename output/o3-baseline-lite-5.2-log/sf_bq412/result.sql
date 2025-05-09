WITH filtered_ads AS (
    SELECT
        r."creative_page_url"                              AS "page_url",
        region.value:"first_shown"::DATE                   AS "first_shown",
        region.value:"last_shown"::DATE                    AS "last_shown",
        dis.value:"removal_reason"::STRING                 AS "removal_reason",
        dis.value:"violation_category"::STRING             AS "violation_category",
        region.value:"times_shown_lower_bound"::NUMBER     AS "times_shown_lower_bound",
        region.value:"times_shown_upper_bound"::NUMBER     AS "times_shown_upper_bound"
    FROM  GOOGLE_ADS.GOOGLE_ADS_TRANSPARENCY_CENTER.REMOVED_CREATIVE_STATS r,
          LATERAL FLATTEN(input => r."region_stats")  region,
          LATERAL FLATTEN(input => r."disapproval")   dis
    WHERE region.value:"region_code"::STRING = 'HR'                                           -- Croatia
      AND region.value:"times_shown_availability_date" IS NULL                               -- availability date is null
      AND region.value:"times_shown_lower_bound"::NUMBER  > 10000                            -- lower bound > 10 000
      AND region.value:"times_shown_upper_bound"::NUMBER  < 25000                            -- upper bound < 25 000
      -- at least one audience‑selection approach is NOT “CRITERIA_UNUSED”
      AND (
            COALESCE(r."audience_selection_approach_info":"contextual_signals"::STRING,'CRITERIA_UNUSED')   <> 'CRITERIA_UNUSED'
         OR COALESCE(r."audience_selection_approach_info":"customer_lists"::STRING,'CRITERIA_UNUSED')        <> 'CRITERIA_UNUSED'
         OR COALESCE(r."audience_selection_approach_info":"demographic_info"::STRING,'CRITERIA_UNUSED')      <> 'CRITERIA_UNUSED'
         OR COALESCE(r."audience_selection_approach_info":"geo_location"::STRING,'CRITERIA_UNUSED')          <> 'CRITERIA_UNUSED'
         OR COALESCE(r."audience_selection_approach_info":"topics_of_interest"::STRING,'CRITERIA_UNUSED')    <> 'CRITERIA_UNUSED'
      )
)
SELECT *
FROM   filtered_ads
ORDER  BY "last_shown" DESC NULLS LAST, "page_url"
LIMIT  5;