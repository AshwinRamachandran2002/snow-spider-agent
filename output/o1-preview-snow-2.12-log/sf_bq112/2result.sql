SELECT
    ROUND(((wage_2017 - wage_1998) / wage_1998) * 100, 4) AS "Wage_growth_rate",
    ROUND(((cpi_2017 - cpi_1998) / cpi_1998) * 100, 4) AS "Inflation_rate"
FROM (
    SELECT
        (SELECT AVG("avg_wkly_wage") * 52
         FROM (
             SELECT "avg_wkly_wage_10_total_all_industries" AS "avg_wkly_wage"
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
        ) AS wage_1998,
        (SELECT AVG("avg_wkly_wage") * 52
         FROM (
             SELECT "avg_wkly_wage_10_total_all_industries" AS "avg_wkly_wage"
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
        ) AS wage_2017,
        (SELECT "value"
         FROM "BLS"."BLS"."CPI_U"
         WHERE "series_id" = 'CUUR0000SA0' AND "period" = 'M13' AND "year" = 1998
        ) AS cpi_1998,
        (SELECT "value"
         FROM "BLS"."BLS"."CPI_U"
         WHERE "series_id" = 'CUUR0000SA0' AND "period" = 'M13' AND "year" = 2017
        ) AS cpi_2017
) AS data;