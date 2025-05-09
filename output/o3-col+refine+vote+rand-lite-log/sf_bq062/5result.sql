WITH license_counts AS (
    SELECT
        pv."System",
        TRIM(f.value::STRING)                     AS "License",
        COUNT(*)                                  AS "PackageCount",
        ROW_NUMBER() OVER (
            PARTITION BY pv."System"
            ORDER BY COUNT(*) DESC
        )                                         AS rn
    FROM "DEPS_DEV_V1"."DEPS_DEV_V1"."PACKAGEVERSIONS" pv,
         LATERAL FLATTEN (input => pv."Licenses") f
    WHERE f.value IS NOT NULL
    GROUP BY
        pv."System",
        TRIM(f.value::STRING)
)
SELECT
    "System",
    "License",
    "PackageCount"
FROM license_counts
WHERE rn = 1
ORDER BY "System";