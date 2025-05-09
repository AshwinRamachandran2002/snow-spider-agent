WITH license_counts AS (
    SELECT
        pv."System",
        LOWER(TRIM(f.value::string))   AS "License",
        COUNT(*)                       AS "UsageCount"
    FROM "DEPS_DEV_V1"."DEPS_DEV_V1"."PACKAGEVERSIONS"  pv
         , LATERAL FLATTEN(INPUT => pv."Licenses")      f
    WHERE pv."Licenses" IS NOT NULL
    GROUP BY
        pv."System",
        LOWER(TRIM(f.value::string))
),
ranked_licenses AS (
    SELECT
        "System",
        "License",
        "UsageCount",
        ROW_NUMBER() OVER (PARTITION BY "System"
                           ORDER BY "UsageCount" DESC, "License") AS rn
    FROM license_counts
)
SELECT
    "System",
    "License",
    "UsageCount"
FROM ranked_licenses
WHERE rn = 1
ORDER BY "System";