WITH wage_1998 AS (
  SELECT AVG("avg_wkly_wage_10_total_all_industries") AS "avg_wage_1998"
  FROM (
    SELECT "avg_wkly_wage_10_total_all_industries"
    FROM "BLS"."BLS_QCEW"."_1998_Q1"
    WHERE "area_fips" = '42003'
    UNION ALL
    SELECT "avg_wkly_wage_10_total_all_industries"
    FROM "BLS"."BLS_QCEW"."_1998_Q2"
    WHERE "area_fips" = '42003'
    UNION ALL
    SELECT "avg_wkly_wage_10_total_all_industries"
    FROM "BLS"."BLS_QCEW"."_1998_Q3"
    WHERE "area_fips" = '42003'
    UNION ALL
    SELECT "avg_wkly_wage_10_total_all_industries"
    FROM "BLS"."BLS_QCEW"."_1998_Q4"
    WHERE "area_fips" = '42003'
  )
),
wage_2017 AS (
  SELECT AVG("avg_wkly_wage_10_total_all_industries") AS "avg_wage_2017"
  FROM (
    SELECT "avg_wkly_wage_10_total_all_industries"
    FROM "BLS"."BLS_QCEW"."_2017_Q1"
    WHERE "area_fips" = '42003'
    UNION ALL
    SELECT "avg_wkly_wage_10_total_all_industries"
    FROM "BLS"."BLS_QCEW"."_2017_Q2"
    WHERE "area_fips" = '42003'
    UNION ALL
    SELECT "avg_wkly_wage_10_total_all_industries"
    FROM "BLS"."BLS_QCEW"."_2017_Q3"
    WHERE "area_fips" = '42003'
    UNION ALL
    SELECT "avg_wkly_wage_10_total_all_industries"
    FROM "BLS"."BLS_QCEW"."_2017_Q4"
    WHERE "area_fips" = '42003'
  )
),
cpi_1998 AS (
  SELECT AVG("value") AS "avg_cpi_1998"
  FROM "BLS"."BLS"."CPI_U"
  WHERE "year" = 1998 AND "item_name" = 'All items' AND "area_code" = '0000'
),
cpi_2017 AS (
  SELECT AVG("value") AS "avg_cpi_2017"
  FROM "BLS"."BLS"."CPI_U"
  WHERE "year" = 2017 AND "item_name" = 'All items' AND "area_code" = '0000'
),
growth_calculations AS (
  SELECT
    ROUND(((wage_2017."avg_wage_2017" - wage_1998."avg_wage_1998") / wage_1998."avg_wage_1998") * 100, 4) AS "Wage_growth_rate",
    ROUND(((cpi_2017."avg_cpi_2017" - cpi_1998."avg_cpi_1998") / cpi_1998."avg_cpi_1998") * 100, 4) AS "Inflation_rate"
  FROM wage_1998, wage_2017, cpi_1998, cpi_2017
)
SELECT * FROM growth_calculations;