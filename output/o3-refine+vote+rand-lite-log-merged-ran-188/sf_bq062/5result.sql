WITH license_counts AS (
    SELECT
        "System",
        f.value::STRING AS "License",
        COUNT(*) AS "PackageCount"
    FROM "DEPS_DEV_V1"."DEPS_DEV_V1"."PACKAGEVERSIONS",
         LATERAL FLATTEN(INPUT => "Licenses") f
    WHERE f.value IS NOT NULL
    GROUP BY
        "System",
        f.value::STRING
),
ranked AS (
    SELECT
        "System",
        "License",
        "PackageCount",
        ROW_NUMBER() OVER (
            PARTITION BY "System"
            ORDER BY "PackageCount" DESC, "License" ASC
        ) AS "rn"
    FROM license_counts
)
SELECT
    "System",
    "License" AS "MostFrequentlyUsedLicense",
    "PackageCount"
FROM ranked
WHERE "rn" = 1
ORDER BY "System";