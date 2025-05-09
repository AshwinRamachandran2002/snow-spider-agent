WITH wage_data_1998 AS (
    SELECT * FROM (
        SELECT * FROM "BLS"."BLS_QCEW"."_1998_Q1"
        UNION ALL
        SELECT * FROM "BLS"."BLS_QCEW"."_1998_Q2"
        UNION ALL
        SELECT * FROM "BLS"."BLS_QCEW"."_1998_Q3"
        UNION ALL
        SELECT * FROM "BLS"."BLS_QCEW"."_1998_Q4"
    ) AS unioned_tables
    WHERE "area_fips" = '42003'
),
wage_data_2017 AS (
    SELECT * FROM (
        SELECT * FROM "BLS"."BLS_QCEW"."_2017_Q1"
        UNION ALL
        SELECT * FROM "BLS"."BLS_QCEW"."_2017_Q2"
        UNION ALL
        SELECT * FROM "BLS"."BLS_QCEW"."_2017_Q3"
        UNION ALL
        SELECT * FROM "BLS"."BLS_QCEW"."_2017_Q4"
    ) AS unioned_tables
    WHERE "area_fips" = '42003'
),
wage_1998 AS (
    SELECT AVG("avg_wkly_wage_10_total_all_industries") * 52 AS "annual_wage_1998"
    FROM wage_data_1998
),
wage_2017 AS (
    SELECT AVG("avg_wkly_wage_10_total_all_industries") * 52 AS "annual_wage_2017"
    FROM wage_data_2017
),
cpi_data AS (
    SELECT "year", AVG("value") AS "avg_cpi"
    FROM "BLS"."BLS"."CPI_U"
    WHERE "item_code" = 'SA0' AND "year" IN (1998, 2017)
    GROUP BY "year"
),
cpi_1998 AS (
    SELECT "avg_cpi" AS "avg_cpi_1998"
    FROM cpi_data
    WHERE "year" = 1998
),
cpi_2017 AS (
    SELECT "avg_cpi" AS "avg_cpi_2017"
    FROM cpi_data
    WHERE "year" = 2017
)
SELECT
    ROUND(((wage_2017."annual_wage_2017" - wage_1998."annual_wage_1998") / wage_1998."annual_wage_1998") * 100, 2) AS "Wage_growth_rate",
    ROUND(((cpi_2017."avg_cpi_2017" - cpi_1998."avg_cpi_1998") / cpi_1998."avg_cpi_1998") * 100, 2) AS "Inflation_rate"
FROM wage_1998, wage_2017, cpi_1998, cpi_2017;