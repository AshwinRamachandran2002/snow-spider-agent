WITH wage_data AS (   -- Allegheny County (FIPS 42003) weekly wages, Q4 snapshots
    SELECT 1998 AS "year",
           CAST("avg_wkly_wage_10_total_all_industries" AS FLOAT) AS "wage"
    FROM   BLS.BLS_QCEW._1998_Q4
    WHERE  "geoid" = '42003'

    UNION ALL

    SELECT 2017 AS "year",
           CAST("avg_wkly_wage_10_total_all_industries" AS FLOAT) AS "wage"
    FROM   BLS.BLS_QCEW._2017_Q4
    WHERE  "geoid" = '42003'
),

cpi_data AS (         -- National CPI-U, All items, annual average (period M13)
    SELECT "year",
           CAST("value" AS FLOAT) AS "cpi"
    FROM   BLS.BLS.C_CPI_U
    WHERE  "series_id" = 'SUUR0000SA0'   -- U.S. city average, all items
      AND  "period"   = 'M13'            -- annual average
      AND  "year" IN (1998, 2017)
),

base AS (
    SELECT
        (SELECT "wage" FROM wage_data WHERE "year" = 1998) AS "wage_1998",
        (SELECT "wage" FROM wage_data WHERE "year" = 2017) AS "wage_2017",
        (SELECT "cpi"  FROM cpi_data  WHERE "year" = 1998) AS "cpi_1998",
        (SELECT "cpi"  FROM cpi_data  WHERE "year" = 2017) AS "cpi_2017"
)

SELECT
    ROUND( ( "wage_2017" - "wage_1998" ) / "wage_1998" * 100 , 2) AS "wage_growth_pct_1998_2017",
    ROUND( ( "cpi_2017"  - "cpi_1998"  ) / "cpi_1998"  * 100 , 2) AS "cpi_growth_pct_1998_2017",
    CASE
        WHEN ( "wage_2017" - "wage_1998" ) / "wage_1998"
           >= ( "cpi_2017"  - "cpi_1998"  ) / "cpi_1998"
        THEN 'Yes'
        ELSE 'No'
    END AS "did_wages_keep_pace_with_inflation"
FROM base;