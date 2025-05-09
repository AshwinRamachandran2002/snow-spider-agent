WITH june_dates AS (
    -- 1.  Only keep one record per country per day in June‑2022
    SELECT DISTINCT
           country_code_2,
           DATE(insert_date) AS insert_date
    FROM   cities
    WHERE  insert_date BETWEEN '2022-06-01' AND '2022-06-30'
),
dated_rows AS (
    -- 2.  Give each country’s dates a row number, then build a key that stays
    --     constant inside a consecutive‑day streak
    SELECT
        country_code_2,
        insert_date,
        JULIANDAY(insert_date)
        - ROW_NUMBER() OVER (PARTITION BY country_code_2
                             ORDER BY insert_date)        AS grp_key
    FROM june_dates
),
streak_lengths AS (
    -- 3.  Length of every consecutive‑day streak
    SELECT
        country_code_2,
        COUNT(*)  AS streak_len
    FROM   dated_rows
    GROUP  BY country_code_2, grp_key
),
country_max AS (
    -- 4.  Longest streak per country
    SELECT
        country_code_2,
        MAX(streak_len) AS max_streak
    FROM   streak_lengths
    GROUP  BY country_code_2
),
overall_max AS (
    -- 5.  Longest streak length observed in any country
    SELECT MAX(max_streak) AS best_streak
    FROM   country_max
)
-- 6.  Return the country/ies whose longest streak equals the overall best
SELECT c.country_code_2
FROM   country_max  AS c
JOIN   overall_max  AS o
  ON   c.max_streak = o.best_streak;