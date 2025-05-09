/*  Did Allegheny County wages keep pace with CPI (all-items U.S. city average)?
    – Wage source: QCEW average weekly wage, all industries (code 10)
      • compare 1998-Q4 vs 2017-Q4 for county FIPS 42003
    – CPI source: C-CPI-U series SUUR0000SA0 (‘U.S. city average – All items’)
      • use annual averages (period M13) for 1998 and 2017                                     */

WITH wage AS (
    SELECT
        w98."avg_wkly_wage_10_total_all_industries" AS "wage_1998",
        w17."avg_wkly_wage_10_total_all_industries" AS "wage_2017"
    FROM "BLS"."BLS_QCEW"."_1998_Q4"  w98
    JOIN "BLS"."BLS_QCEW"."_2017_Q4"  w17
          ON w98."area_fips" = w17."area_fips"
    WHERE w98."area_fips" = '42003'            -- Allegheny County, PA
),
cpi AS (
    SELECT
        MIN(CASE WHEN "year" = 1998 THEN "value" END) AS "cpi_1998",
        MIN(CASE WHEN "year" = 2017 THEN "value" END) AS "cpi_2017"
    FROM "BLS"."BLS"."C_CPI_U"
    WHERE "series_id" = 'SUUR0000SA0'          -- U.S. city avg, all items
      AND "period"   = 'M13'                   -- annual average
      AND "year" IN (1998, 2017)
)

SELECT
    ROUND( (w."wage_2017" / w."wage_1998" - 1) * 100 , 2)  AS "wage_growth_pct_1998_2017",
    ROUND( (c."cpi_2017"  / c."cpi_1998"  - 1) * 100 , 2)  AS "cpi_growth_pct_1998_2017",
    CASE
        WHEN  (w."wage_2017" / w."wage_1998") >= (c."cpi_2017" / c."cpi_1998")
        THEN 'Yes'
        ELSE 'No'
    END                                                    AS "wages_kept_up_with_inflation?"
FROM wage w
CROSS JOIN cpi c;