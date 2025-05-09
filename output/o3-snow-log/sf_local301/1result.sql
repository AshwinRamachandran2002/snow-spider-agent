/*  Percentage change in total sales between the
    4 weeks BEFORE (18-May–14-Jun) and the 4 weeks AFTER (15-Jun–12-Jul)
    for calendar years 2018, 2019 and 2020                                    */

WITH weekly AS (
    SELECT
        "calendar_year"        AS calendar_year,
        TO_DATE("week_date", 'YYYY-MM-DD')  AS week_dt,
        "sales"                AS sales
    FROM BANK_SALES_TRADING.BANK_SALES_TRADING.CLEANED_WEEKLY_SALES
    WHERE "calendar_year" IN (2018, 2019, 2020)
)

SELECT
    calendar_year                                                AS "year",
    
    /* total sales in the 4 weeks leading up to 15-June */
    SUM(
        CASE
            WHEN week_dt BETWEEN
                 DATEADD(day, -28, TO_DATE(calendar_year || '-06-15'))   -- 18-May
                 AND DATEADD(day,  -1, TO_DATE(calendar_year || '-06-15'))-- 14-Jun
            THEN sales
            ELSE 0
        END
    )                                                             AS "pre_sales",
    
    /* total sales in the 4 weeks following 15-June */
    SUM(
        CASE
            WHEN week_dt BETWEEN
                 TO_DATE(calendar_year || '-06-15')                      -- 15-Jun
                 AND DATEADD(day, 27, TO_DATE(calendar_year || '-06-15'))-- 12-Jul
            THEN sales
            ELSE 0
        END
    )                                                             AS "post_sales",
    
    /* percentage change */
    ROUND(
        (
            SUM(
                CASE
                    WHEN week_dt BETWEEN
                         TO_DATE(calendar_year || '-06-15')
                         AND DATEADD(day, 27, TO_DATE(calendar_year || '-06-15'))
                    THEN sales
                    ELSE 0
                END
            )
            -
            SUM(
                CASE
                    WHEN week_dt BETWEEN
                         DATEADD(day, -28, TO_DATE(calendar_year || '-06-15'))
                         AND DATEADD(day, -1,  TO_DATE(calendar_year || '-06-15'))
                    THEN sales
                    ELSE 0
                END
            )
        )
        /
        NULLIF(
            SUM(
                CASE
                    WHEN week_dt BETWEEN
                         DATEADD(day, -28, TO_DATE(calendar_year || '-06-15'))
                         AND DATEADD(day, -1,  TO_DATE(calendar_year || '-06-15'))
                    THEN sales
                    ELSE 0
                END
            ),
            0
        )
        * 100
        , 4
    )                                                             AS "pct_change"
FROM weekly
GROUP BY calendar_year
ORDER BY calendar_year;