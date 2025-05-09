SELECT
    "System" AS system,
    "License" AS most_frequent_license
FROM (
    SELECT
        pv."System",
        l.value::STRING AS "License",
        COUNT(*) AS license_count,
        ROW_NUMBER() OVER (
            PARTITION BY pv."System"
            ORDER BY COUNT(*) DESC, l.value::STRING
        ) AS rn
    FROM "DEPS_DEV_V1"."DEPS_DEV_V1"."PACKAGEVERSIONS" pv,
         LATERAL FLATTEN(input => pv."Licenses") l
    WHERE pv."Licenses" IS NOT NULL
    GROUP BY pv."System", l.value::STRING
)
WHERE rn = 1
ORDER BY system;