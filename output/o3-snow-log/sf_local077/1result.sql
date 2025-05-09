/* --------------------------------------------------------------
   1.  Calculate average-composition per interest per month
       (composition / index_value)
   2.  Select the interest with the highest average-composition
       for each month from 2018-09 to 2019-08
   3.  Return the 3-month rolling average of these maxima together
       with prior-month and two-months-ago winners
   -------------------------------------------------------------- */

WITH monthly_avg AS (                     /* step-1 */
    SELECT
        m."_year"  AS year_n,
        m."_month" AS month_n,
        TO_DATE(TO_CHAR(m."_year") || '-' || LPAD(m."_month",2,'0') || '-01') AS month_start,
        m."interest_id"       AS interest_id,
        mp."interest_name"    AS interest_name,
        m."composition" / NULLIF(m."index_value",0)               AS avg_composition
    FROM   BANK_SALES_TRADING.BANK_SALES_TRADING."INTEREST_METRICS"  m
    JOIN   BANK_SALES_TRADING.BANK_SALES_TRADING."INTEREST_MAP"      mp
           ON mp."id" = m."interest_id"
    WHERE  (m."_year" = 2018 AND m."_month" >= 9)  -- Sept-2018 …
       OR  (m."_year" = 2019 AND m."_month" <= 8)  -- … Aug-2019
),

monthly_top AS (                          /* step-2: top per month */
    SELECT
        year_n,
        month_n,
        month_start,
        interest_id,
        interest_name,
        avg_composition,
        ROW_NUMBER() OVER (PARTITION BY year_n, month_n
                           ORDER BY avg_composition DESC NULLS LAST,
                                    interest_id)                    AS rn
    FROM   monthly_avg
),

monthly_max AS (                          /* step-3: winners only */
    SELECT
        year_n,
        month_n,
        month_start,
        interest_name,
        avg_composition                                         AS max_index_comp
    FROM   monthly_top
    WHERE  rn = 1
)

SELECT
    TO_CHAR(month_start,'YYYY-MM')                               AS "date",
    interest_name                                                AS "top_interest",
    ROUND(max_index_comp,4)                                      AS "max_index_composition",
    /* 3-month rolling average of the monthly maxima */
    ROUND(
        AVG(max_index_comp)
        OVER (ORDER BY month_start
              ROWS BETWEEN 2 PRECEDING AND CURRENT ROW),4)       AS "three_month_rolling_avg",
    /* prior-month winner */
    LAG(interest_name,1)  OVER (ORDER BY month_start)            AS "top_interest_1_month_ago",
    ROUND(LAG(max_index_comp,1) OVER (ORDER BY month_start),4)   AS "max_index_comp_1_month_ago",
    /* two-months-ago winner */
    LAG(interest_name,2)  OVER (ORDER BY month_start)            AS "top_interest_2_months_ago",
    ROUND(LAG(max_index_comp,2) OVER (ORDER BY month_start),4)   AS "max_index_comp_2_months_ago"
FROM   monthly_max
ORDER  BY month_start;