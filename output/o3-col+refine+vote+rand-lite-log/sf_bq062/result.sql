WITH license_counts AS (
    SELECT
        pv."System",
        TRIM(f.value::STRING) AS "License",
        COUNT(*) AS "License_Count"
    FROM DEPS_DEV_V1.DEPS_DEV_V1.PACKAGEVERSIONS pv,
         LATERAL FLATTEN (INPUT => pv."Licenses") f
    GROUP BY
        pv."System",
        TRIM(f.value::STRING)
)
SELECT
    "System",
    "License" AS "Most_Frequent_License",
    "License_Count"
FROM (
    SELECT
        lc.*,
        ROW_NUMBER() OVER (PARTITION BY lc."System"
                           ORDER BY lc."License_Count" DESC) AS rn
    FROM license_counts lc
)
WHERE rn = 1
ORDER BY "System";