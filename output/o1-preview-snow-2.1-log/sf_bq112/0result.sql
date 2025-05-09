WITH wages_1998 AS (
  SELECT AVG("avg_wkly_wage_10_total_all_industries") AS avg_wkly_wage
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
  ) AS wages
),
wages_2017 AS (
  SELECT AVG("avg_wkly_wage_10_total_all_industries") AS avg_wkly_wage
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
  ) AS wages
),
cpi_1998 AS (
  SELECT AVG("value") AS cpi
  FROM "BLS"."BLS"."CPI_U"
  WHERE "item_name" = 'All items' AND "period" = 'M13' AND "year" = 1998
),
cpi_2017 AS (
  SELECT AVG("value") AS cpi
  FROM "BLS"."BLS"."CPI_U"
  WHERE "item_name" = 'All items' AND "period" = 'M13' AND "year" = 2017
)
SELECT
  ROUND(((wages_2017.avg_wkly_wage * 52 - wages_1998.avg_wkly_wage * 52) / (wages_1998.avg_wkly_wage * 52)) * 100, 4) AS "Wage_growth_rate",
  ROUND(((cpi_2017.cpi - cpi_1998.cpi) / cpi_1998.cpi) * 100, 4) AS "Inflation_rate"
FROM
  wages_1998,
  wages_2017,
  cpi_1998,
  cpi_2017;