WITH LicenseCounts AS (
    SELECT
        t."System",
        l.value::STRING AS "License",
        COUNT(*) AS "PackageCount"
    FROM
        "DEPS_DEV_V1"."DEPS_DEV_V1"."PACKAGEVERSIONS" t,
        LATERAL FLATTEN(input => t."Licenses") l
    WHERE
        l.value::STRING IS NOT NULL AND l.value::STRING != ''
    GROUP BY
        t."System",
        l.value::STRING
),
RankedLicenses AS (
    SELECT
        "System",
        "License",
        "PackageCount",
        ROW_NUMBER() OVER (PARTITION BY "System" ORDER BY "PackageCount" DESC NULLS LAST) AS RN
    FROM
        LicenseCounts
)
SELECT
    "System",
    "License" AS "Most_Frequent_License",
    "PackageCount"
FROM
    RankedLicenses
WHERE
    RN = 1
ORDER BY
    "System";