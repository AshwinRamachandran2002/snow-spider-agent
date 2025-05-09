WITH base AS (   
    SELECT  
        TO_DATE("week_date",'YYYY-MM-DD')                                AS week_dt, 
        "sales"
    FROM BANK_SALES_TRADING.BANK_SALES_TRADING.CLEANED_WEEKLY_SALES
), 

filtered AS (    
    SELECT  
        EXTRACT(YEAR FROM week_dt)                                       AS yr,
        CASE
            /* 4 weeks AFTER (and incl.) 15-June */
            WHEN week_dt >= DATE_FROM_PARTS(EXTRACT(YEAR FROM week_dt),6,15)
             AND week_dt <  DATEADD(day,28 , DATE_FROM_PARTS(EXTRACT(YEAR FROM week_dt),6,15))
                 THEN 'post' 
            /* 4 weeks BEFORE 15-June */
            WHEN week_dt <  DATE_FROM_PARTS(EXTRACT(YEAR FROM week_dt),6,15)
             AND week_dt >= DATEADD(day,-28, DATE_FROM_PARTS(EXTRACT(YEAR FROM week_dt),6,15))
                 THEN 'pre'
            ELSE NULL
        END                                                             AS period,
        "sales"                                                         AS sales_amt
    FROM base
    WHERE EXTRACT(YEAR FROM week_dt) IN (2018,2019,2020)
), 

agg AS (    
    SELECT  
        yr,
        SUM(CASE WHEN period='pre'  THEN sales_amt END)                 AS pre_sales,
        SUM(CASE WHEN period='post' THEN sales_amt END)                 AS post_sales
    FROM filtered
    WHERE period IS NOT NULL
    GROUP BY yr
)

SELECT  
    yr                                                   AS "calendar_year",
    ROUND( (post_sales - pre_sales) / NULLIF(pre_sales,0) * 100 , 4 )
                                                        AS "pct_change_sales_around_mid_june"
FROM agg
ORDER BY yr;