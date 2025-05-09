WITH licenses AS (
    SELECT
        "System",
        "Name",
        l.value::string AS "License"
    FROM "DEPS_DEV_V1"."DEPS_DEV_V1"."PACKAGEVERSIONS",
         LATERAL FLATTEN(INPUT => "Licenses") l
),
license_counts AS (
    SELECT
        "System",
        "License",
        COUNT(DISTINCT "Name") AS "PackageCount"
    FROM licenses
    GROUP BY
        "System",
        "License"
),
ranked AS (
    SELECT
        "System",
        "License",
        "PackageCount",
        ROW_NUMBER() OVER (
            PARTITION BY "System"
            ORDER BY "PackageCount" DESC, "License" ASC
        ) AS rn
    FROM license_counts
)
SELECT
    "System",
    "License"           AS "MostFrequentLicense",
    "PackageCount"
FROM ranked
WHERE rn = 1
ORDER BY "System";