WITH exploded AS (
    /* get one row per (System, Package Name, License) */
    SELECT
        pv."System",
        pv."Name",
        TRIM(f.value::string) AS "License"
    FROM DEPS_DEV_V1.DEPS_DEV_V1.PACKAGEVERSIONS pv,
         LATERAL FLATTEN(INPUT => pv."Licenses") f
    WHERE pv."Licenses" IS NOT NULL
      AND TRIM(f.value::string) <> ''
),
license_counts AS (
    /* count how many distinct packages use each license in every system */
    SELECT
        "System",
        "License",
        COUNT(DISTINCT "Name") AS "PackageCount"
    FROM exploded
    GROUP BY
        "System",
        "License"
)
SELECT
    "System",
    "License"   AS "Most_Frequent_License",
    "PackageCount"
FROM license_counts
QUALIFY
    ROW_NUMBER() OVER (
        PARTITION BY "System"
        ORDER BY "PackageCount" DESC NULLS LAST, "License"
    ) = 1
ORDER BY
    "System";