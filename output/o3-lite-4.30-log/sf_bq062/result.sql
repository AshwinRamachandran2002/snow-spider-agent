SELECT
    "System"  AS system,
    "License" AS most_frequent_license
FROM (
    SELECT
        pv."System",
        f.value::STRING                       AS "License",
        COUNT(*)                              AS license_count,
        ROW_NUMBER() OVER (
            PARTITION BY pv."System"
            ORDER BY COUNT(*) DESC, f.value::STRING
        )                                    AS rn
    FROM DEPS_DEV_V1.DEPS_DEV_V1.PACKAGEVERSIONS pv,
         LATERAL FLATTEN(INPUT => pv."Licenses") f
    WHERE f.value IS NOT NULL
      AND TRIM(f.value::STRING) <> ''
    GROUP BY
        pv."System",
        f.value
) ranked
WHERE rn = 1
ORDER BY system;