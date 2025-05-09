SELECT
    pv."System",
    f.value::string AS "License",
    COUNT(*) AS "OccurrenceCount"
FROM DEPS_DEV_V1.DEPS_DEV_V1."PACKAGEVERSIONS" AS pv,
     LATERAL FLATTEN(INPUT => pv."Licenses") AS f
WHERE f.value IS NOT NULL
GROUP BY
    pv."System",
    f.value::string
QUALIFY ROW_NUMBER() OVER (
           PARTITION BY pv."System"
           ORDER BY COUNT(*) DESC, f.value::string
       ) = 1
ORDER BY
    pv."System";