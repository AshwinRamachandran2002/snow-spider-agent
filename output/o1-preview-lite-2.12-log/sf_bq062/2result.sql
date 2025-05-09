WITH LicenseCounts AS (
    SELECT 
        t."System", 
        REPLACE(f.value::STRING, '"', '') AS "License", 
        COUNT(*) AS "PackageCount"
    FROM DEPS_DEV_V1.DEPS_DEV_V1.PACKAGEVERSIONS t,
         LATERAL FLATTEN(input => t."Licenses") f
    GROUP BY 
        t."System", 
        REPLACE(f.value::STRING, '"', '')
),
RankedLicenses AS (
    SELECT
        "System",
        "License",
        "PackageCount",
        ROW_NUMBER() OVER (
            PARTITION BY "System" 
            ORDER BY "PackageCount" DESC NULLS LAST
        ) AS rn
    FROM LicenseCounts
)
SELECT
    "System",
    "License" AS "Most_Frequent_License"
FROM RankedLicenses
WHERE rn = 1
ORDER BY "System";