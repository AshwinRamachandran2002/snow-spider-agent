WITH filtered AS (   /* only keep the required 12 months */
    SELECT
        month_year,
        interest_id,
        composition,
        index_value
    FROM interest_metrics
    WHERE (_year = 2018 AND _month >= 9)
       OR (_year = 2019 AND _month <= 8)
),

/* average composition for every interest each month            */
/* (specification: composition divided by index_value)           */
avg_comp_per_interest AS (
    SELECT
        month_year,
        interest_id,
        AVG(composition / index_value) AS avg_comp
    FROM filtered
    GROUP BY month_year, interest_id
),

/* choose the interest with the largest average‐composition      */
monthly_rank AS (
    SELECT
        month_year,
        interest_id,
        avg_comp,
        ROW_NUMBER() OVER (PARTITION BY month_year
                           ORDER BY avg_comp DESC, interest_id) AS rn
    FROM avg_comp_per_interest
),
monthly_top AS (
    SELECT month_year,
           interest_id,
           avg_comp
    FROM   monthly_rank
    WHERE  rn = 1
),

/* attach the readable interest name */
monthly_top_named AS (
    SELECT m.month_year,
           i.interest_name,
           m.avg_comp
    FROM   monthly_top m
    LEFT JOIN interest_map i
           ON i.id = m.interest_id
),

/* add previous‑month information and 3‑month rolling average    */
final AS (
    SELECT
        mt.month_year                                                     AS date,
        mt.interest_name                                                  AS interest_name,
        ROUND(mt.avg_comp,4)                                              AS max_index_composition,

        LAG(mt.interest_name,1) OVER (ORDER BY substr(mt.month_year,4,4),
                                               substr(mt.month_year,1,2)) AS prev1_interest_name,
        ROUND(LAG(mt.avg_comp,1) OVER (ORDER BY substr(mt.month_year,4,4),
                                                 substr(mt.month_year,1,2)),4)
                                                                         AS prev1_max_index_composition,

        LAG(mt.interest_name,2) OVER (ORDER BY substr(mt.month_year,4,4),
                                               substr(mt.month_year,1,2)) AS prev2_interest_name,
        ROUND(LAG(mt.avg_comp,2) OVER (ORDER BY substr(mt.month_year,4,4),
                                                 substr(mt.month_year,1,2)),4)
                                                                         AS prev2_max_index_composition,

        ROUND(AVG(mt.avg_comp) OVER (ORDER BY substr(mt.month_year,4,4),
                                               substr(mt.month_year,1,2)
                                     ROWS BETWEEN 2 PRECEDING AND CURRENT ROW),4)
                                                                         AS three_month_rolling_average
    FROM   monthly_top_named mt
)

SELECT *
FROM   final
ORDER  BY substr(date,4,4),     /* year  */
          substr(date,1,2);     /* month */