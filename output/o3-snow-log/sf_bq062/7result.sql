WITH license_counts AS (
    SELECT  
        "System",
        l.value::string                           AS "License",
        COUNT(*)                                  AS "LicenseCount"
    FROM DEPS_DEV_V1.DEPS_DEV_V1.PACKAGEVERSIONS
    ,    LATERAL FLATTEN(input => "Licenses") l          -- explode the JSON/ARRAY of licenses
    WHERE "Licenses" IS NOT NULL
    GROUP BY "System", l.value
), ranked AS (                                                -- pick the top-occurring license per system
    SELECT
        "System",
        "License",
        "LicenseCount",
        ROW_NUMBER() OVER (PARTITION BY "System"
                           ORDER BY "LicenseCount" DESC NULLS LAST, "License") AS rn
    FROM license_counts
)
SELECT
    "System",
    "License",
    "LicenseCount"
FROM ranked
WHERE rn = 1
ORDER BY "System";