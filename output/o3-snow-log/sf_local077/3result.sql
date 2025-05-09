/* -----------------------------------------------------------
   Interest analysis  (Sep-2018 ➜ Aug-2019)
-----------------------------------------------------------*/
WITH base AS (            /* 1.  Clean & create proper date  */
    SELECT
        TRY_TO_DATE('01-'||TRIM("month_year"),'DD-MM-YYYY')    AS month_dt ,
        "interest_id"                                          AS interest_id ,
        "composition"                                          AS composition ,
        "index_value"                                          AS index_value
    FROM BANK_SALES_TRADING.BANK_SALES_TRADING.INTEREST_METRICS
    WHERE "month_year" IS NOT NULL
),

metrics AS (          /* 2.  Avg-composition for every interest & month */
    SELECT
        month_dt ,
        interest_id ,
        composition / NULLIF(index_value,0)                    AS avg_comp
    FROM base
    WHERE month_dt BETWEEN '2018-09-01' AND '2019-08-31'
      AND month_dt IS NOT NULL
),

monthly_top AS (      /* 3.  Select the highest avg_comp each month     */
    SELECT
        month_dt ,
        interest_id ,
        ROUND(avg_comp,4)                                      AS max_index_comp ,
        ROW_NUMBER() OVER (PARTITION BY month_dt
                           ORDER BY avg_comp DESC NULLS LAST)  AS rn
    FROM metrics
),

top_interest AS (     /* 4.  Attach interest names – keep rn = 1        */
    SELECT
        mt.month_dt ,
        im."interest_name" ,
        mt.max_index_comp
    FROM monthly_top mt
    JOIN BANK_SALES_TRADING.BANK_SALES_TRADING.INTEREST_MAP im
          ON im."id" = CAST(mt.interest_id AS NUMBER)
    WHERE mt.rn = 1
),

rolling AS (          /* 5.  3-month rolling avg + prior-month details  */
    SELECT
        month_dt ,
        "interest_name"                                         AS current_month_interest ,
        max_index_comp                                          AS max_index_composition ,
        ROUND(
            AVG(max_index_comp)
              OVER (ORDER BY month_dt
                    ROWS BETWEEN 2 PRECEDING AND CURRENT ROW)
        ,4)                                                     AS rolling_avg_3m ,
        LAG("interest_name",1)  OVER (ORDER BY month_dt)        AS prev_month_interest ,
        LAG(max_index_comp,1)   OVER (ORDER BY month_dt)        AS prev_month_max_index_composition ,
        LAG("interest_name",2)  OVER (ORDER BY month_dt)        AS two_months_ago_interest ,
        LAG(max_index_comp,2)   OVER (ORDER BY month_dt)        AS two_months_ago_max_index_composition
    FROM top_interest
)

SELECT
    TO_CHAR(month_dt,'YYYY-MM')                   AS "date" ,
    current_month_interest ,
    max_index_composition ,
    rolling_avg_3m ,
    prev_month_interest ,
    prev_month_max_index_composition ,
    two_months_ago_interest ,
    two_months_ago_max_index_composition
FROM rolling
ORDER BY month_dt;