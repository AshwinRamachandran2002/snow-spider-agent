WITH wage_quarterly AS (
    /* Allegheny County, PA (FIPS 42003) – quarterly average-weekly wages
       List every required quarterly table explicitly */
    SELECT 1998 AS "year", "avg_wkly_wage_10_total_all_industries" AS "wage"
      FROM BLS.BLS_QCEW._1998_Q1 WHERE "area_fips" = '42003'
    UNION ALL
    SELECT 1998, "avg_wkly_wage_10_total_all_industries"
      FROM BLS.BLS_QCEW._1998_Q2 WHERE "area_fips" = '42003'
    UNION ALL
    SELECT 1998, "avg_wkly_wage_10_total_all_industries"
      FROM BLS.BLS_QCEW._1998_Q3 WHERE "area_fips" = '42003'
    UNION ALL
    SELECT 1998, "avg_wkly_wage_10_total_all_industries"
      FROM BLS.BLS_QCEW._1998_Q4 WHERE "area_fips" = '42003'

    UNION ALL
    SELECT 2017, "avg_wkly_wage_10_total_all_industries"
      FROM BLS.BLS_QCEW._2017_Q1 WHERE "area_fips" = '42003'
    UNION ALL
    SELECT 2017, "avg_wkly_wage_10_total_all_industries"
      FROM BLS.BLS_QCEW._2017_Q2 WHERE "area_fips" = '42003'
    UNION ALL
    SELECT 2017, "avg_wkly_wage_10_total_all_industries"
      FROM BLS.BLS_QCEW._2017_Q3 WHERE "area_fips" = '42003'
    UNION ALL
    SELECT 2017, "avg_wkly_wage_10_total_all_industries"
      FROM BLS.BLS_QCEW._2017_Q4 WHERE "area_fips" = '42003'
),
wage_annual AS (
    /* Compute the annual average of the quarterly wages */
    SELECT
        "year",
        AVG("wage") AS "avg_weekly_wage"
    FROM wage_quarterly
    GROUP BY "year"
),
cpi AS (
    /* U.S. city average CPI for All Items (‘SA0’), annual averages (period M13) */
    SELECT
        "year",
        "value" AS "cpi_value"
    FROM BLS.BLS.CPI_U
    WHERE "area_code" = '0'
      AND "item_code" = 'SA0'
      AND "period"     = 'M13'
      AND "year" IN (1998, 2017)
),
growth AS (
    SELECT
        w17."avg_weekly_wage" AS "wage_2017",
        w98."avg_weekly_wage" AS "wage_1998",
        (w17."avg_weekly_wage" - w98."avg_weekly_wage") / w98."avg_weekly_wage" * 100 AS "wage_growth_pct",
        c17."cpi_value"        AS "cpi_2017",
        c98."cpi_value"        AS "cpi_1998",
        (c17."cpi_value" - c98."cpi_value") / c98."cpi_value" * 100 AS "cpi_growth_pct"
    FROM wage_annual w98
    JOIN wage_annual w17 ON w17."year" = 2017
    JOIN cpi c98         ON c98."year" = 1998
    JOIN cpi c17         ON c17."year" = 2017
    WHERE w98."year" = 1998
)
SELECT
    ROUND("wage_growth_pct", 2) AS "wage_growth_percent_1998_to_2017",
    ROUND("cpi_growth_pct",  2) AS "cpi_growth_percent_1998_to_2017"
FROM growth;