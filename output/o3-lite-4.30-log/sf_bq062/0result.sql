SELECT
    system,
    most_frequent_license
FROM (
    SELECT
        pv."System"                              AS system,
        f.value::STRING                          AS most_frequent_license,
        ROW_NUMBER() OVER (
            PARTITION BY pv."System"
            ORDER BY COUNT(DISTINCT pv."Name") DESC
        )                                        AS rn
    FROM DEPS_DEV_V1.DEPS_DEV_V1.PACKAGEVERSIONS pv,
         LATERAL FLATTEN(INPUT => pv."Licenses") f
    GROUP BY
        pv."System",
        f.value::STRING
)
WHERE rn = 1
ORDER BY system;