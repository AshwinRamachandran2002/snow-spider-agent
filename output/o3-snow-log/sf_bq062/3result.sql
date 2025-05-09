WITH "license_counts" AS (
    SELECT
        pv."System",
        lic.value::STRING AS "License",
        COUNT(*) AS "PackageCount"
    FROM
        DEPS_DEV_V1.DEPS_DEV_V1.PACKAGEVERSIONS pv,
        LATERAL FLATTEN(INPUT => pv."Licenses") lic
    GROUP BY
        pv."System",
        lic.value
),
"ranked" AS (
    SELECT
        "System",
        "License",
        "PackageCount",
        ROW_NUMBER() OVER (
            PARTITION BY "System"
            ORDER BY "PackageCount" DESC NULLS LAST
        ) AS rn
    FROM
        "license_counts"
)
SELECT
    "System",
    "License",
    "PackageCount"
FROM
    "ranked"
WHERE
    rn = 1
ORDER BY
    "System";