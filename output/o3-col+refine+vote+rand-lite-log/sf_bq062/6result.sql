SELECT
    "System",
    f.value::STRING AS "Most_Frequent_License",
    COUNT(*)        AS "Package_Count"
FROM
    "DEPS_DEV_V1"."DEPS_DEV_V1"."PACKAGEVERSIONS",
    LATERAL FLATTEN(input => "Licenses") f
GROUP BY
    "System",
    f.value::STRING
QUALIFY
    ROW_NUMBER() OVER (PARTITION BY "System"
                       ORDER BY COUNT(*) DESC NULLS LAST) = 1
ORDER BY
    "System";