/*  Four‐week sales before vs. after 15 June for 2018-2020          */
/*  – aggregated across all regions, platforms, segments, etc.     */

WITH base AS (   -- convert string week_date to DATE and keep only required years
    SELECT
        "calendar_year",
        TO_DATE("week_date")          AS week_dt,
        "sales"
    FROM BANK_SALES_TRADING.BANK_SALES_TRADING.CLEANED_WEEKLY_SALES
    WHERE "calendar_year" IN (2018, 2019, 2020)
),
windows AS (     -- label each row as belonging to the 4-week “BEFORE” or “AFTER” window
    SELECT
        "calendar_year",
        CASE
            WHEN week_dt <  TO_DATE(CONCAT("calendar_year", '-06-15'))
             AND week_dt >= DATEADD(WEEK, -4, TO_DATE(CONCAT("calendar_year", '-06-15')))
                 THEN 'BEFORE'
            WHEN week_dt >  TO_DATE(CONCAT("calendar_year", '-06-15'))
             AND week_dt <= DATEADD(WEEK,  4, TO_DATE(CONCAT("calendar_year", '-06-15')))
                 THEN 'AFTER'
        END                                                    AS window_flag,
        "sales"
    FROM base
)
SELECT
    "calendar_year",
    SUM(CASE WHEN window_flag = 'BEFORE' THEN "sales" END)      AS "sales_before",
    SUM(CASE WHEN window_flag = 'AFTER'  THEN "sales" END)      AS "sales_after",
    ROUND(
        (   SUM(CASE WHEN window_flag = 'AFTER'  THEN "sales" END)
          - SUM(CASE WHEN window_flag = 'BEFORE' THEN "sales" END) )
        / NULLIF(SUM(CASE WHEN window_flag = 'BEFORE' THEN "sales" END),0) * 100
    , 4)                                                        AS "pct_change_sales"
FROM windows
WHERE window_flag IS NOT NULL          -- keep only rows inside the two 4-week windows
GROUP BY "calendar_year"
ORDER BY "calendar_year";