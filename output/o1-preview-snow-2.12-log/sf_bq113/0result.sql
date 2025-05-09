SELECT
    t2."county_name",
    ROUND(
        ((t3."month3_emplvl_23_construction" - t1."month3_emplvl_23_construction") /
        NULLIF(t1."month3_emplvl_23_construction", 0) * 100), 4
    ) AS "percentage_increase"
FROM BLS.BLS_QCEW."_2000_Q4" t1
JOIN BLS.BLS_QCEW."_2018_Q4" t3
    ON t1."area_fips" = t3."area_fips"
JOIN BLS.GEO_US_BOUNDARIES."COUNTIES" t2
    ON t1."area_fips" = t2."county_fips_code"
WHERE t2."state_fips_code" = '49'
    AND t1."month3_emplvl_23_construction" IS NOT NULL
    AND t3."month3_emplvl_23_construction" IS NOT NULL
ORDER BY "percentage_increase" DESC NULLS LAST
LIMIT 1;