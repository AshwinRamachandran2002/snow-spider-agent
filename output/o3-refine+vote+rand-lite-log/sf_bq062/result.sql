WITH license_counts AS (
    SELECT
        "System",
        l.value::string       AS "License",
        COUNT(*)              AS "LicenseCount"
    FROM "DEPS_DEV_V1"."DEPS_DEV_V1"."PACKAGEVERSIONS",
         LATERAL FLATTEN(input => "Licenses") l
    GROUP BY "System", l.value
),
ranked AS (
    SELECT
        "System",
        "License",
        "LicenseCount",
        ROW_NUMBER() OVER (PARTITION BY "System"
                           ORDER BY "LicenseCount" DESC, "License") AS rn
    FROM license_counts
)
SELECT
    "System",
    "License"        AS "MostFrequentlyUsedLicense",
    "LicenseCount"
FROM ranked
WHERE rn = 1
ORDER BY "System";