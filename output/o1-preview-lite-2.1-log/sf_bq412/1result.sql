WITH filtered_ads AS (
    SELECT t."creative_page_url" AS "Page_URL",
           f.value:"first_shown"::TIMESTAMP AS "First_Shown_Time",
           f.value:"last_shown"::TIMESTAMP AS "Last_Shown_Time",
           f.value:"times_shown_lower_bound"::NUMBER AS "Lower_Bound_Shown_Times",
           f.value:"times_shown_upper_bound"::NUMBER AS "Upper_Bound_Shown_Times"
    FROM "GOOGLE_ADS"."GOOGLE_ADS_TRANSPARENCY_CENTER"."REMOVED_CREATIVE_STATS" t,
         LATERAL FLATTEN(input => t."region_stats") f
    WHERE f.value:"region_code"::STRING = 'HR'
      AND f.value:"times_shown_lower_bound"::NUMBER > 10000
      AND f.value:"times_shown_upper_bound"::NUMBER < 25000
),
audience_match AS (
    SELECT DISTINCT t."creative_page_url"
    FROM "GOOGLE_ADS"."GOOGLE_ADS_TRANSPARENCY_CENTER"."REMOVED_CREATIVE_STATS" t,
         LATERAL FLATTEN(input => t."audience_selection_approach_info") a
    WHERE a.key IN ('demographic_info', 'geo_location', 'contextual_signals', 'customer_lists', 'topics_of_interest')
      AND a.value::STRING != 'CRITERIA_UNUSED'
),
disapproval_info AS (
    SELECT t."creative_page_url",
           d.value:"removal_reason"::STRING AS "Removal_Reason",
           d.value:"violation_category"::STRING AS "Violation_Category"
    FROM "GOOGLE_ADS"."GOOGLE_ADS_TRANSPARENCY_CENTER"."REMOVED_CREATIVE_STATS" t,
         LATERAL FLATTEN(input => t."disapproval") d
)
SELECT fa."Page_URL",
       fa."First_Shown_Time",
       fa."Last_Shown_Time",
       di."Removal_Reason",
       di."Violation_Category",
       ROUND(fa."Lower_Bound_Shown_Times", 4) AS "Lower_Bound_Shown_Times",
       ROUND(fa."Upper_Bound_Shown_Times", 4) AS "Upper_Bound_Shown_Times"
FROM filtered_ads fa
JOIN audience_match am ON fa."Page_URL" = am."creative_page_url"
LEFT JOIN disapproval_info di ON fa."Page_URL" = di."creative_page_url"
ORDER BY fa."Last_Shown_Time" DESC NULLS LAST
LIMIT 5;