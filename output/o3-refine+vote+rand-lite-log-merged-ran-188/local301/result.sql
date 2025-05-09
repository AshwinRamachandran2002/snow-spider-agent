WITH sales_weeks AS (          -- keep only the 3 required calendar years
    SELECT  calendar_year  AS yr,
            DATE(week_date) AS week_start,
            sales
    FROM    cleaned_weekly_sales
    WHERE   calendar_year IN (2018,2019,2020)
),
flagged AS (                   -- tag each week as the 4‑weeks “before” or “after” 15‑June
    SELECT  yr,
            CASE
                WHEN week_start >= DATE(yr || '-06-15','-28 day')
                 AND week_start <  DATE(yr || '-06-15')            THEN 'before'
                WHEN week_start >= DATE(yr || '-06-15')
                 AND week_start <  DATE(yr || '-06-15','+28 day')  THEN 'after'
            END                             AS period,
            sales
    FROM    sales_weeks
    WHERE   week_start BETWEEN DATE(yr || '-06-15','-28 day') 
                           AND DATE(yr || '-06-15','+27 day')      -- ensures only the 8 weeks of interest
),
totals AS (                    -- total sales in each period for every year
    SELECT  yr,
            period,
            SUM(sales) AS total_sales
    FROM    flagged
    WHERE   period IS NOT NULL
    GROUP BY yr, period
),
pivot AS (                     -- reshape to “before” and “after” columns
    SELECT  yr                                                     AS calendar_year,
            MAX(CASE WHEN period='before' THEN total_sales END)    AS before_sales,
            MAX(CASE WHEN period='after'  THEN total_sales END)    AS after_sales
    FROM    totals
    GROUP BY yr
)
SELECT  calendar_year,
        before_sales,
        after_sales,
        ROUND( (after_sales - before_sales) * 100.0 / before_sales , 4) AS pct_change
FROM    pivot
ORDER BY calendar_year;