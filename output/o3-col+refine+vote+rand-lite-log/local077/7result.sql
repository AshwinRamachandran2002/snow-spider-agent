WITH month_interest AS (          -- 1. interest-level data limited to Sep-2018 → Aug-2019
    SELECT
        im._year,
        im._month,
        printf('%04d-%02d', im._year, im._month)              AS month_date,
        mp.interest_name,
        ROUND(im.composition / NULLIF(im.index_value, 0), 4)  AS avg_comp,
        ROW_NUMBER() OVER (                                   -- rank interests within month
            PARTITION BY im._year, im._month
            ORDER BY im.composition / NULLIF(im.index_value, 0) DESC
        )                                                     AS rn
    FROM   interest_metrics AS im
    JOIN   interest_map      AS mp
           ON im.interest_id = mp.id
    WHERE (im._year = 2018 AND im._month >= 9)
       OR (im._year = 2019 AND im._month <= 8)
),
monthly_max AS (               -- 2. keep only the #1 interest each month
    SELECT
        month_date,
        interest_name,
        avg_comp
    FROM   month_interest
    WHERE  rn = 1
),
final AS (                     -- 3. add 3-month rolling avg + prior-month winners
    SELECT
        month_date,
        interest_name                                    AS current_top_interest,
        avg_comp                                         AS max_index_comp,
        ROUND(AVG(avg_comp) OVER (
                ORDER BY month_date
                ROWS BETWEEN 2 PRECEDING AND CURRENT ROW
             ), 4)                                       AS rolling_avg,
        LAG(interest_name, 1) OVER (ORDER BY month_date) AS top_interest_1_month_ago,
        LAG(avg_comp,      1) OVER (ORDER BY month_date) AS max_index_comp_1_month_ago,
        LAG(interest_name, 2) OVER (ORDER BY month_date) AS top_interest_2_months_ago,
        LAG(avg_comp,      2) OVER (ORDER BY month_date) AS max_index_comp_2_months_ago
    FROM   monthly_max
)
SELECT *
FROM   final
ORDER BY month_date;