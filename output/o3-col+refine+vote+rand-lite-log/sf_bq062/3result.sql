WITH license_counts AS (
    SELECT
        pv."System",
        f.value::STRING AS "License",
        COUNT(*)        AS "PkgCount"
    FROM "DEPS_DEV_V1"."DEPS_DEV_V1"."PACKAGEVERSIONS" pv,
         LATERAL FLATTEN(input => pv."Licenses") f
    GROUP BY
        pv."System",
        f.value::STRING
)
SELECT
    "System",
    MAX_BY("License", "PkgCount") AS "MostFrequentLicense",
    MAX("PkgCount")               AS "PackageCount"
FROM license_counts
GROUP BY "System"
ORDER BY "System";