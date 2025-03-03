SELECT c."county_name", ROUND(((t2."total_employment_2018" - t1."total_employment_2000") / t1."total_employment_2000") * 100, 4) AS "Percentage_Increase"
FROM (
  SELECT "area_fips", SUM("month3_emplvl_23_construction") AS "total_employment_2000"
  FROM (
    SELECT "area_fips", "month3_emplvl_23_construction" FROM "BLS"."BLS_QCEW"."_2000_Q1" WHERE "area_fips" LIKE '49%'
    UNION ALL
    SELECT "area_fips", "month3_emplvl_23_construction" FROM "BLS"."BLS_QCEW"."_2000_Q2" WHERE "area_fips" LIKE '49%'
    UNION ALL
    SELECT "area_fips", "month3_emplvl_23_construction" FROM "BLS"."BLS_QCEW"."_2000_Q3" WHERE "area_fips" LIKE '49%'
    UNION ALL
    SELECT "area_fips", "month3_emplvl_23_construction" FROM "BLS"."BLS_QCEW"."_2000_Q4" WHERE "area_fips" LIKE '49%'
  ) t
  GROUP BY "area_fips"
  HAVING SUM("month3_emplvl_23_construction") > 0
) t1
JOIN (
  SELECT "area_fips", SUM("month3_emplvl_23_construction") AS "total_employment_2018"
  FROM (
    SELECT "area_fips", "month3_emplvl_23_construction" FROM "BLS"."BLS_QCEW"."_2018_Q1" WHERE "area_fips" LIKE '49%'
    UNION ALL
    SELECT "area_fips", "month3_emplvl_23_construction" FROM "BLS"."BLS_QCEW"."_2018_Q2" WHERE "area_fips" LIKE '49%'
    UNION ALL
    SELECT "area_fips", "month3_emplvl_23_construction" FROM "BLS"."BLS_QCEW"."_2018_Q3" WHERE "area_fips" LIKE '49%'
    UNION ALL
    SELECT "area_fips", "month3_emplvl_23_construction" FROM "BLS"."BLS_QCEW"."_2018_Q4" WHERE "area_fips" LIKE '49%'
  ) t
  GROUP BY "area_fips"
) t2 ON t1."area_fips" = t2."area_fips"
JOIN "BLS"."GEO_US_BOUNDARIES"."COUNTIES" c ON t1."area_fips" = c."county_fips_code"
WHERE c."state_fips_code" = '49'
ORDER BY "Percentage_Increase" DESC NULLS LAST
LIMIT 1;