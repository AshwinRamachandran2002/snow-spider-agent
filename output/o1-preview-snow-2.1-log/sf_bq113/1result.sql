SELECT
    c."county_name",
    ROUND(((e2018."month3_emplvl_23_construction" - e2000."month3_emplvl_23_construction") / e2000."month3_emplvl_23_construction" * 100), 4) AS "Percentage_increase"
FROM
    "BLS"."GEO_US_BOUNDARIES"."COUNTIES" c
JOIN
    "BLS"."BLS_QCEW"."_2000_Q4" e2000 ON c."geo_id" = e2000."geoid"
JOIN
    "BLS"."BLS_QCEW"."_2018_Q4" e2018 ON c."geo_id" = e2018."geoid"
WHERE
    c."state_fips_code" = '49'
    AND e2000."month3_emplvl_23_construction" IS NOT NULL
    AND e2000."month3_emplvl_23_construction" != 0
    AND e2018."month3_emplvl_23_construction" IS NOT NULL
ORDER BY
    "Percentage_increase" DESC NULLS LAST
LIMIT 1;