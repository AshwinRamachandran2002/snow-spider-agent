/* Most frequently-used license(s) for each package-management system */
SELECT
    "System",
    "License",
    "License_Count"
FROM (
    SELECT
        pv."System",
        f.value::STRING                AS "License",
        COUNT(*)                       AS "License_Count",
        MAX(COUNT(*)) OVER (
            PARTITION BY pv."System"
        )                              AS "Max_Count"
    FROM DEPS_DEV_V1.DEPS_DEV_V1.PACKAGEVERSIONS  AS pv,
         LATERAL FLATTEN(input => pv."Licenses") AS f
    GROUP BY
        pv."System",
        f.value
)
WHERE "License_Count" = "Max_Count"          -- keep only the most common license(s) per system
ORDER BY
    "System";