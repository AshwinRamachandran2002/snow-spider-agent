WITH region_hr AS (
    /* unpack region_stats and keep only Croatia (HR) rows */
    SELECT
        t."creative_page_url",
        rs.value:"first_shown"::DATE            AS "first_shown",
        rs.value:"last_shown"::DATE             AS "last_shown",
        rs.value:"times_shown_lower_bound"::INT AS "times_shown_lower_bound",
        rs.value:"times_shown_upper_bound"::INT AS "times_shown_upper_bound",
        rs.value:"times_shown_availability_date"      AS "times_shown_availability_date",
        t."audience_selection_approach_info",
        t."disapproval"
    FROM GOOGLE_ADS.GOOGLE_ADS_TRANSPARENCY_CENTER.REMOVED_CREATIVE_STATS t,
         LATERAL FLATTEN(input => t."region_stats") rs
    WHERE rs.value:"region_code"::STRING = 'HR'
),
disapproval_first AS (
    /* take the first disapproval object per creative */
    SELECT
        r.*,
        d.value                               AS "dis_obj",
        ROW_NUMBER() OVER (PARTITION BY r."creative_page_url" ORDER BY d.index) AS rn
    FROM region_hr r,
         LATERAL FLATTEN(input => r."disapproval") d
)
SELECT
    "creative_page_url"                                       AS "page_url",
    "first_shown",
    "last_shown",
    "dis_obj":"removal_reason"::STRING                        AS "removal_reason",
    "dis_obj":"violation_category"::STRING                    AS "violation_category",
    "times_shown_lower_bound",
    "times_shown_upper_bound"
FROM disapproval_first
WHERE rn = 1                                     -- keep first disapproval element
  AND "times_shown_availability_date" IS NULL
  AND "times_shown_lower_bound"  > 10000
  AND "times_shown_upper_bound"  < 25000
  /* at least one non-unused audience-selection approach */
  AND (
        NVL("audience_selection_approach_info":"contextual_signals"::STRING, 'CRITERIA_UNUSED')      != 'CRITERIA_UNUSED'
     OR NVL("audience_selection_approach_info":"customer_lists"::STRING,      'CRITERIA_UNUSED')      != 'CRITERIA_UNUSED'
     OR NVL("audience_selection_approach_info":"demographic_info"::STRING,    'CRITERIA_UNUSED')      != 'CRITERIA_UNUSED'
     OR NVL("audience_selection_approach_info":"geo_location"::STRING,        'CRITERIA_UNUSED')      != 'CRITERIA_UNUSED'
     OR NVL("audience_selection_approach_info":"topics_of_interest"::STRING,  'CRITERIA_UNUSED')      != 'CRITERIA_UNUSED'
     )
ORDER BY "last_shown" DESC NULLS LAST
LIMIT 5;