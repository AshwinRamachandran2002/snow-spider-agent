WITH june AS (
    SELECT 
        country_code_2,
        insert_date,
        CASE
            WHEN julianday(insert_date) 
                 - julianday(LAG(insert_date) OVER (
                        PARTITION BY country_code_2 
                        ORDER BY insert_date)) = 1 
            THEN 0 ELSE 1
        END AS new_streak_flag
    FROM cities
    WHERE insert_date BETWEEN '2022-06-01' AND '2022-06-30'
),
streaked AS (
    SELECT
        country_code_2,
        insert_date,
        SUM(new_streak_flag) OVER (
            PARTITION BY country_code_2 
            ORDER BY insert_date) AS streak_id
    FROM june
),
streak_lengths AS (
    SELECT
        country_code_2,
        streak_id,
        COUNT(*) AS streak_len
    FROM streaked
    GROUP BY country_code_2, streak_id
),
best_per_country AS (
    SELECT
        country_code_2,
        MAX(streak_len) AS max_streak_len
    FROM streak_lengths
    GROUP BY country_code_2
),
global_max AS (
    SELECT MAX(max_streak_len) AS longest_streak
    FROM best_per_country
)
SELECT 
    b.country_code_2
FROM best_per_country b
JOIN global_max g
  ON b.max_streak_len = g.longest_streak
ORDER BY b.country_code_2;