WITH "hr_ads" AS (
    SELECT
        t."creative_page_url",
        fr.value:"first_shown"::DATE            AS "first_shown",
        fr.value:"last_shown"::DATE             AS "last_shown",
        fr.value:"times_shown_lower_bound"::INT AS "times_shown_lower_bound",
        fr.value:"times_shown_upper_bound"::INT AS "times_shown_upper_bound",
        fd.value:"removal_reason"::STRING       AS "removal_reason",
        fd.value:"violation_category"::STRING   AS "violation_category"
    FROM "GOOGLE_ADS"."GOOGLE_ADS_TRANSPARENCY_CENTER"."REMOVED_CREATIVE_STATS" t
         , LATERAL FLATTEN(input => t."region_stats")                       fr
         , LATERAL FLATTEN(input => t."disapproval")                        fd
         , LATERAL FLATTEN(input => t."audience_selection_approach_info")   fa
    WHERE fr.value:"region_code"::STRING            = 'HR'
      AND fr.value:"times_shown_lower_bound"::INT   > 10000
      AND fr.value:"times_shown_upper_bound"::INT   < 25000
      AND fr.value:"times_shown_availability_date" IS NULL
      AND fa.value::STRING                          <> 'CRITERIA_UNUSED'
)
SELECT
    "creative_page_url",
    "first_shown",
    "last_shown",
    "removal_reason",
    "violation_category",
    "times_shown_lower_bound",
    "times_shown_upper_bound"
FROM (
    SELECT
        *,
        ROW_NUMBER() OVER (PARTITION BY "creative_page_url"
                           ORDER BY "last_shown" DESC) AS "rn"
    FROM "hr_ads"
)
WHERE "rn" = 1
ORDER BY "last_shown" DESC NULLS LAST
LIMIT 5;