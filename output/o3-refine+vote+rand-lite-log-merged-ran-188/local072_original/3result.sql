WITH jan22 AS (                     -- all rows inserted during January 2022
    SELECT *
    FROM cities
    WHERE insert_date >= '2022-01-01'
      AND insert_date <  '2022-02-01'
),
country_day_counts AS (             -- how many different January‑2022 days each country appears
    SELECT country_code_2,
           COUNT(DISTINCT insert_date) AS num_days
    FROM jan22
    GROUP BY country_code_2
    HAVING num_days = 9             -- ← the country mentioned in the task
),
target_country AS (                 -- keep (the first) country that satisfies the rule
    SELECT country_code_2
    FROM country_day_counts
    ORDER BY country_code_2
    LIMIT 1
),
country_dates AS (                  -- distinct January‑2022 dates for that country
    SELECT DISTINCT insert_date
    FROM jan22
    WHERE country_code_2 = (SELECT country_code_2 FROM target_country)
),
ordered_dates AS (                  -- give each date a row number to detect gaps
    SELECT insert_date,
           ROW_NUMBER() OVER (ORDER BY insert_date)                AS rn,
           CAST(julianday(insert_date) AS INTEGER)                 AS jd
    FROM country_dates
),
date_groups AS (                    -- same (jd‑rn) ⇒ consecutive block
    SELECT insert_date,
           jd - rn AS grp
    FROM ordered_dates
),
streaks AS (                        -- length of each consecutive block
    SELECT grp,
           MIN(insert_date) AS streak_start,
           MAX(insert_date) AS streak_end,
           COUNT(*)        AS streak_length
    FROM date_groups
    GROUP BY grp
),
longest_streak AS (                 -- longest consecutive block
    SELECT *
    FROM streaks
    ORDER BY streak_length DESC, streak_start
    LIMIT 1
),
period_entries AS (                 -- all city rows that fall inside the longest streak
    SELECT *
    FROM jan22
    WHERE country_code_2 = (SELECT country_code_2 FROM target_country)
      AND insert_date BETWEEN (SELECT streak_start FROM longest_streak)
                          AND (SELECT streak_end   FROM longest_streak)
)
SELECT  cc.country_name,
        ls.streak_start,
        ls.streak_end,
        ls.streak_length,
        SUM(CASE WHEN pe.capital = 1 THEN 1 ELSE 0 END) AS capital_entries,
        COUNT(*)                                        AS total_entries,
        ROUND(
            1.0 * SUM(CASE WHEN pe.capital = 1 THEN 1 ELSE 0 END) 
            / COUNT(*), 
        4)                                              AS capital_proportion
FROM period_entries        pe
JOIN cities_countries      cc ON cc.country_code_2 = pe.country_code_2
CROSS JOIN longest_streak  ls
GROUP BY cc.country_name, ls.streak_start, ls.streak_end, ls.streak_length;