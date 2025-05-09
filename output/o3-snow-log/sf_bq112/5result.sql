/* 1998-2017 growth comparison
   • Allegheny County (FIPS 42003) average weekly wage – all industries, QCEW Q4 files
   • CPI-U “All items, U.S. city average” – annual average of monthly (M01-M12) values   */

WITH
/* Allegheny County wages */
wage_1998 AS (
    SELECT "avg_wkly_wage_10_total_all_industries"  AS w1998
    FROM   BLS.BLS_QCEW._1998_Q4
    WHERE  "geoid" = '42003'
),
wage_2017 AS (
    SELECT "avg_wkly_wage_10_total_all_industries"  AS w2017
    FROM   BLS.BLS_QCEW._2017_Q4
    WHERE  "geoid" = '42003'
),

/* CPI-U annual averages (use mean of M01-M12 to avoid missing M13 rows) */
cpi_1998 AS (
    SELECT AVG("value") AS cpi1998
    FROM   BLS.BLS.C_CPI_U
    WHERE  "area_name" = 'U.S. city average'
      AND  "item_name" = 'All items'
      AND  "year"      = 1998
      AND  "period"    LIKE 'M__'                     -- months 01-12
),
cpi_2017 AS (
    SELECT AVG("value") AS cpi2017
    FROM   BLS.BLS.C_CPI_U
    WHERE  "area_name" = 'U.S. city average'
      AND  "item_name" = 'All items'
      AND  "year"      = 2017
      AND  "period"    LIKE 'M__'
)

/* percentage growth 1998-2017 */
SELECT
    ROUND( (w2017 - w1998) / w1998 * 100 , 2 )  AS "wage_growth_pct_1998_2017",
    ROUND( (cpi2017 - cpi1998) / cpi1998 * 100 , 2 )  AS "cpi_growth_pct_1998_2017"
FROM wage_1998, wage_2017, cpi_1998, cpi_2017;