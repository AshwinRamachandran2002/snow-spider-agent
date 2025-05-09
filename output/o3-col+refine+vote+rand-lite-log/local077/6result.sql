-- 1.  Calculate average-composition for every interest each month  
-- 2.  Keep the single highest average per month (monthly “max index composition”)  
-- 3.  Add 3-month rolling average of those maxima  
-- 4.  Attach the top interests from one and two months earlier
WITH interest_avg AS (
    SELECT
        printf('%04d-%02d', CAST(im."_year"  AS INTEGER),
                           CAST(im."_month" AS INTEGER))          AS month_start,
        mp.interest_name,
        AVG(im.composition / NULLIF(im.index_value, 0))            AS avg_comp
    FROM   interest_metrics AS im
    JOIN   interest_map     AS mp
           ON mp.id = im.interest_id
    WHERE  (im."_year"  = 2018 AND im."_month" BETWEEN 9 AND 12)
       OR  (im."_year"  = 2019 AND im."_month" BETWEEN 1 AND 8)
    GROUP  BY month_start, mp.interest_name
),
monthly_max AS (
    SELECT month_start,
           interest_name,
           avg_comp AS max_index_composition
    FROM  (
        SELECT
               month_start,
               interest_name,
               avg_comp,
               ROW_NUMBER() OVER (PARTITION BY month_start
                                  ORDER BY avg_comp DESC) AS rn
        FROM   interest_avg
    )
    WHERE rn = 1
),
final AS (
    SELECT
        month_start,
        interest_name,
        ROUND(max_index_composition, 4)                                           AS max_index_composition,
        ROUND(AVG(max_index_composition) OVER (
                 ORDER BY month_start
                 ROWS BETWEEN 2 PRECEDING AND CURRENT ROW), 4)                   AS rolling_3m_avg,
        LAG(interest_name, 1) OVER (ORDER BY month_start)                         AS prev1_interest,
        ROUND(LAG(max_index_composition, 1) OVER (ORDER BY month_start), 4)       AS prev1_max_index_composition,
        LAG(interest_name, 2) OVER (ORDER BY month_start)                         AS prev2_interest,
        ROUND(LAG(max_index_composition, 2) OVER (ORDER BY month_start), 4)       AS prev2_max_index_composition
    FROM   monthly_max
)
SELECT *
FROM   final
ORDER  BY month_start;