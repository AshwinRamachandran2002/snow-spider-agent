WITH monthly_avg AS (                       -- 1. calc avg(comp/index) for every interest each month
    SELECT 
        "month_year",
        CAST(SUBSTR("month_year",4,4)||SUBSTR("month_year",1,2) AS INTEGER)  AS ym_key,
        "interest_id",
        AVG("composition"/NULLIF("index_value",0))                           AS avg_comp
    FROM "interest_metrics"
    WHERE ("_year" = 2018 AND "_month" >= 9)      -- Sep-2018 … Aug-2019
       OR ("_year" = 2019 AND "_month" <= 8)
    GROUP BY "month_year","interest_id"
),
monthly_max AS (                           -- 2. pick the interest with the highest avg_comp each month
    SELECT 
        "month_year",
        ym_key,
        "interest_id",
        ROUND(avg_comp,4)      AS max_index_comp,
        RANK() OVER (PARTITION BY "month_year" ORDER BY avg_comp DESC) AS rk
    FROM monthly_avg
),
top_per_month AS (                         -- keep only the monthly winner
    SELECT "month_year",ym_key,"interest_id",max_index_comp
    FROM   monthly_max
    WHERE  rk = 1
),
rolling AS (                               -- 3-month rolling average of winners’ comps
    SELECT
        t.*,
        ROUND(
            AVG(t.max_index_comp) OVER (
                ORDER BY t.ym_key
                ROWS BETWEEN 2 PRECEDING AND CURRENT ROW
            )
        ,4) AS rolling_3m_avg
    FROM top_per_month t
)
SELECT
    r."month_year",
    cur."interest_name"            AS current_interest,
    r."max_index_comp",
    r."rolling_3m_avg",
    p1n."interest_name"            AS prev1_interest,
    p1."max_index_comp"            AS prev1_max_comp,
    p2n."interest_name"            AS prev2_interest,
    p2."max_index_comp"            AS prev2_max_comp
FROM rolling              r
LEFT JOIN rolling         p1  ON p1.ym_key = r.ym_key - 1
LEFT JOIN rolling         p2  ON p2.ym_key = r.ym_key - 2
LEFT JOIN "interest_map"  cur ON cur."id" = r."interest_id"
LEFT JOIN "interest_map"  p1n ON p1n."id" = p1."interest_id"
LEFT JOIN "interest_map"  p2n ON p2n."id" = p2."interest_id"
ORDER BY r.ym_key;