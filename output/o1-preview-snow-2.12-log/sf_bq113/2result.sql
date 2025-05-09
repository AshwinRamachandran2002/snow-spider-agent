SELECT c."county_name",
       ROUND(((q2018."month3_emplvl_23_construction" - q2000."month3_emplvl_23_construction") / q2000."month3_emplvl_23_construction") * 100, 4) AS "Percentage_increase"
FROM "BLS"."GEO_US_BOUNDARIES"."COUNTIES" c
JOIN "BLS"."BLS_QCEW"."_2000_Q4" q2000
  ON c."county_fips_code" = q2000."area_fips"
JOIN "BLS"."BLS_QCEW"."_2018_Q4" q2018
  ON c."county_fips_code" = q2018."area_fips"
WHERE c."state_fips_code" = '49'
  AND q2000."month3_emplvl_23_construction" > 0
ORDER BY "Percentage_increase" DESC NULLS LAST
LIMIT 1;