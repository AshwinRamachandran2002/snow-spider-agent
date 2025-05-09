WITH jan22 AS (
    SELECT city_id,
           capital,
           DATE(insert_date) AS d,
           country_code_2
    FROM cities
    WHERE SUBSTR(insert_date,1,7) = '2022-01'
),
-- country that has data on exactly nine January‑2022 days
country9 AS (
    SELECT country_code_2
    FROM jan22
    GROUP BY country_code_2
    HAVING COUNT(DISTINCT d) = 9
),
-- group its January days into consecutive‑day islands
day_groups AS (
    SELECT d,
           julianday(d) - ROW_NUMBER() OVER (ORDER BY d) AS grp_id
    FROM jan22
    WHERE country_code_2 = (SELECT country_code_2 FROM country9)
    GROUP BY d
),
streaks AS (
    SELECT grp_id,
           MIN(d) AS start_d,
           MAX(d) AS end_d,
           COUNT(*) AS len
    FROM day_groups
    GROUP BY grp_id
),
-- longest consecutive streak
longest AS (
    SELECT start_d, end_d
    FROM streaks
    ORDER BY len DESC, start_d
    LIMIT 1
),
-- all city rows for that country within the longest streak
rows_period AS (
    SELECT c.*
    FROM cities AS c
    JOIN longest
      ON DATE(c.insert_date) BETWEEN longest.start_d AND longest.end_d
    WHERE c.country_code_2 = (SELECT country_code_2 FROM country9)
)
SELECT
    cc.country_name                                 AS country,
    longest.start_d                                 AS consecutive_period_start,
    longest.end_d                                   AS consecutive_period_end,
    COUNT(*)                                        AS total_entries_in_period,
    SUM(CASE WHEN capital = 1 THEN 1 ELSE 0 END)    AS capital_entries_in_period,
    printf('%.4f',
           1.0 * SUM(CASE WHEN capital = 1 THEN 1 ELSE 0 END) / COUNT(*)
          )                                         AS capital_entry_proportion
FROM rows_period
CROSS JOIN longest
JOIN cities_countries AS cc
  ON cc.country_code_2 = (SELECT country_code_2 FROM country9);