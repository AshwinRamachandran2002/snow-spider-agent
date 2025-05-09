WITH monthly_avg AS (          -- 1. average composition for every interest each month
    SELECT   _year,
             _month,
             month_year,
             interest_id,
             AVG(composition / NULLIF(index_value,0))     AS avg_comp
    FROM     interest_metrics
    WHERE   (_year = 2018 AND _month >= 9)
       OR   (_year = 2019 AND _month <= 8)
    GROUP BY _year, _month, interest_id
),
monthly_top AS (               -- 2. pick the highest-average interest each month
    SELECT   ma.*,
             RANK() OVER (PARTITION BY _year, _month
                          ORDER BY avg_comp DESC)         AS rk
    FROM     monthly_avg  ma
),
winners AS (                    -- 3. attach the interest name for the monthly winner
    SELECT   mt._year,
             mt._month,
             mt.month_year,
             im.interest_name,
             mt.avg_comp                              AS max_index_composition
    FROM     monthly_top      mt
    JOIN     interest_map     im  ON im.id = mt.interest_id
    WHERE    mt.rk = 1
)
-- 4. final report with rolling avg and lag columns
SELECT  w.month_year                                  AS date,
        w.interest_name                               AS current_top_interest,
        ROUND(w.max_index_composition,4)              AS current_max_index_comp,
        ROUND(AVG(w.max_index_composition)
              OVER (ORDER BY w._year, w._month
                    ROWS BETWEEN 2 PRECEDING AND CURRENT ROW),4)  AS rolling_avg_3m,
        LAG(w.interest_name,1)
              OVER (ORDER BY w._year, w._month)       AS top_interest_1_month_ago,
        ROUND(LAG(w.max_index_composition,1)
              OVER (ORDER BY w._year, w._month),4)    AS max_index_comp_1_month_ago,
        LAG(w.interest_name,2)
              OVER (ORDER BY w._year, w._month)       AS top_interest_2_months_ago,
        ROUND(LAG(w.max_index_composition,2)
              OVER (ORDER BY w._year, w._month),4)    AS max_index_comp_2_months_ago
FROM    winners w
ORDER BY w._year, w._month;