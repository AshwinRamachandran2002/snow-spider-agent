WITH june AS (
    SELECT DISTINCT insert_date,
           country_code_2
    FROM cities
    WHERE insert_date LIKE '2022-06-%'
),
numbered AS (
    SELECT country_code_2,
           insert_date,
           ROW_NUMBER() OVER (PARTITION BY country_code_2
                              ORDER BY insert_date)        AS rn,
           julianday(insert_date)                         AS jd
    FROM june
),
streaks AS (
    SELECT country_code_2,
           (jd - rn) AS streak_id               -- constant within each consecutive-day streak
    FROM numbered
),
streak_lengths AS (
    SELECT country_code_2,
           streak_id,
           COUNT(*) AS streak_len
    FROM streaks
    GROUP BY country_code_2, streak_id
),
longest_per_country AS (
    SELECT country_code_2,
           MAX(streak_len) AS longest_streak
    FROM streak_lengths
    GROUP BY country_code_2
),
max_streak AS (
    SELECT MAX(longest_streak) AS max_len
    FROM longest_per_country
)
SELECT l.country_code_2
FROM   longest_per_country l
JOIN   max_streak m
ON     l.longest_streak = m.max_len;