WITH license_counts AS (
    SELECT
        "System",
        TRIM(f.value::string)             AS "License",
        COUNT(*)                          AS "PackageCount"
    FROM DEPS_DEV_V1.DEPS_DEV_V1.PACKAGEVERSIONS
         , LATERAL FLATTEN(input => "Licenses") f
    WHERE f.value IS NOT NULL
    GROUP BY "System", TRIM(f.value::string)
),
ranked_licenses AS (
    SELECT
        "System",
        "License",
        "PackageCount",
        RANK() OVER (PARTITION BY "System" ORDER BY "PackageCount" DESC) AS "rank_in_system"
    FROM license_counts
)
SELECT
    "System",
    "License",
    "PackageCount"
FROM ranked_licenses
WHERE "rank_in_system" = 1
ORDER BY "System";