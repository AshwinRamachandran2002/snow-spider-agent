-- Most frequently used license for every package system
SELECT
    "System",
    "License"                AS "Most_Frequent_License",
    "License_Count"          AS "Frequency"
FROM (
    SELECT
        pv."System",
        lic.value::STRING     AS "License",
        COUNT(*)              AS "License_Count",
        ROW_NUMBER() OVER (
            PARTITION BY pv."System"
            ORDER BY COUNT(*) DESC
        )                    AS rn
    FROM DEPS_DEV_V1.DEPS_DEV_V1.PACKAGEVERSIONS  pv,
         LATERAL FLATTEN(INPUT => pv."Licenses") lic
    GROUP BY
        pv."System",
        lic.value::STRING
)
WHERE rn = 1
ORDER BY "Frequency" DESC NULLS LAST;