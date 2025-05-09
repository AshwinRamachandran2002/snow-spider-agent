WITH licenses_expanded AS (  -- one row per (system, license)
    SELECT
        "System",
        lic.value::string AS "License"
    FROM "DEPS_DEV_V1"."DEPS_DEV_V1"."PACKAGEVERSIONS",
         LATERAL FLATTEN(INPUT => "Licenses") lic
    WHERE lic.value IS NOT NULL
),
license_counts AS (          -- how often each license is used per system
    SELECT
        "System",
        "License",
        COUNT(*) AS "UsageCount"
    FROM licenses_expanded
    GROUP BY
        "System",
        "License"
),
ranked AS (                  -- pick the most frequent license for each system
    SELECT
        "System",
        "License",
        "UsageCount",
        ROW_NUMBER() OVER (PARTITION BY "System"
                           ORDER BY "UsageCount" DESC) AS rn
    FROM license_counts
)
SELECT
    "System",
    "License",
    "UsageCount"
FROM ranked
WHERE rn = 1
ORDER BY "System";