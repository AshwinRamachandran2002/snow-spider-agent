/* -----------------------------------------------------------
   % CHANGE IN SALES – 4 WEEKS BEFORE vs. 4 WEEKS AFTER 15 JUNE
   FOR CALENDAR YEARS 2018, 2019 AND 2020
   ----------------------------------------------------------- */

WITH "weekly" AS (      /* convert text date to real DATE and keep sales */
    SELECT
        TRY_TO_DATE("week_date", 'DD/MM/YY') AS week_dt,
        "sales"                              AS sales
    FROM BANK_SALES_TRADING.BANK_SALES_TRADING."WEEKLY_SALES"
    WHERE TRY_TO_DATE("week_date", 'DD/MM/YY') IS NOT NULL
),

"ranges" AS (           /* build the two 4-week windows per year */
    SELECT
        yr                                     AS "year",
        DATE_FROM_PARTS(yr, 6, 15)             AS mid_june,
        DATEADD(day, -28, DATE_FROM_PARTS(yr, 6, 15)) AS start_before,
        DATEADD(day,  28, DATE_FROM_PARTS(yr, 6, 15)) AS end_after
    FROM (SELECT 2018 AS yr UNION ALL SELECT 2019 UNION ALL SELECT 2020)
),

"calc" AS (             /* aggregate sales for each window */
    SELECT
        r."year",
        SUM(CASE
                WHEN w.week_dt >= r.start_before
                 AND w.week_dt <  r.mid_june  THEN w.sales
            END) AS before_sales,
        SUM(CASE
                WHEN w.week_dt >= r.mid_june
                 AND w.week_dt <  r.end_after THEN w.sales
            END) AS after_sales
    FROM "ranges" r
    LEFT JOIN "weekly" w
           ON w.week_dt >= r.start_before
          AND w.week_dt <  r.end_after
    GROUP BY r."year"
)

SELECT
    "year",
    before_sales,
    after_sales,
    ROUND( (after_sales - before_sales)
           / NULLIF(before_sales, 0) * 100 , 4) AS pct_change
FROM "calc"
ORDER BY "year";