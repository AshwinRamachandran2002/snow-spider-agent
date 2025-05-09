WITH license_counts AS (
    SELECT
        pv."System",
        fl.value::string          AS "License",
        COUNT(*)                  AS "LicenseCount"
    FROM DEPS_DEV_V1.DEPS_DEV_V1."PACKAGEVERSIONS" AS pv,
         LATERAL FLATTEN(input => pv."Licenses") AS fl
    WHERE pv."Licenses" IS NOT NULL
    GROUP BY
        pv."System",
        fl.value
),
ranked_licenses AS (
    SELECT
        "System",
        "License",
        "LicenseCount",
        ROW_NUMBER() OVER (
            PARTITION BY "System"
            ORDER BY "LicenseCount" DESC, "License" ASC
        ) AS rn
    FROM license_counts
)
SELECT
    "System",
    "License"        AS "Most_Frequent_License",
    "LicenseCount"   AS "Usage_Count"
FROM ranked_licenses
WHERE rn = 1
ORDER BY "System";