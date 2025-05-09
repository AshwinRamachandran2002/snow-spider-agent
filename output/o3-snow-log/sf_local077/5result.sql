WITH base AS (   -- 1.  keep months Sept-2018 … Aug-2019 and work out the ratio
    SELECT  
           TO_DATE('01-'||"month_year",'DD-MM-YYYY')       AS month_dt ,   -- first day of month
           "month_year",
           CAST("interest_id" AS NUMBER)                   AS interest_id ,
           "composition" ,
           "index_value" ,
           ("composition" / NULLIF("index_value",0) )      AS max_index_comp     -- ratio required
    FROM   BANK_SALES_TRADING.BANK_SALES_TRADING.INTEREST_METRICS
    WHERE ( ("_year" = 2018 AND "_month" >= 9)             -- Sept-2018 …
            OR ("_year" = 2019 AND "_month" <= 8) )        -- … Aug-2019
),
monthly_top AS (   -- 2. find the single highest-ratio interest each month
    SELECT  month_dt ,
            "month_year",
            im."interest_name",
            b.max_index_comp ,
            ROW_NUMBER() OVER (PARTITION BY month_dt 
                               ORDER BY b.max_index_comp DESC NULLS LAST) AS rn
    FROM           base b
    JOIN           BANK_SALES_TRADING.BANK_SALES_TRADING.INTEREST_MAP im
                  ON im."id" = b.interest_id
)
,top_only AS (     -- 3. keep only the #1 per month
    SELECT  month_dt,
            TO_CHAR(month_dt,'YYYY-MM')                    AS month_label,
            "interest_name",
            max_index_comp
    FROM    monthly_top
    WHERE   rn = 1
)
SELECT
       month_label                                     AS "date",
       "interest_name"                                 AS "current_month_interest",
       ROUND(max_index_comp,4)                         AS "current_month_max_index_comp",
       ROUND(AVG(max_index_comp) OVER (ORDER BY month_dt 
                                       ROWS BETWEEN 2 PRECEDING AND CURRENT ROW),4)
                                                      AS "rolling_avg_3m",
       LAG("interest_name",1)  OVER (ORDER BY month_dt)        AS "interest_-1m",
       ROUND(LAG(max_index_comp,1) OVER (ORDER BY month_dt),4) AS "max_index_comp_-1m",
       LAG("interest_name",2)  OVER (ORDER BY month_dt)        AS "interest_-2m",
       ROUND(LAG(max_index_comp,2) OVER (ORDER BY month_dt),4) AS "max_index_comp_-2m"
FROM   top_only
ORDER  BY month_dt;