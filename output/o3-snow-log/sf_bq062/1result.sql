WITH flattened AS (
    SELECT
        "System",
        TRIM(LOWER(f.value::string)) AS "License"
    FROM DEPS_DEV_V1.DEPS_DEV_V1.PACKAGEVERSIONS
    ,   LATERAL FLATTEN(input => "Licenses") f
    WHERE "Licenses" IS NOT NULL
),
license_counts AS (
    SELECT
        "System",
        "License",
        COUNT(*) AS "PackageCount"
    FROM flattened
    GROUP BY "System", "License"
),
ranked AS (
    SELECT
        "System",
        "License",
        "PackageCount",
        ROW_NUMBER() OVER (PARTITION BY "System" ORDER BY "PackageCount" DESC) AS rn
    FROM license_counts
)
SELECT
    "System",
    "License"              AS "MostFrequentLicense",
    "PackageCount"
FROM ranked
WHERE rn = 1
ORDER BY "System";