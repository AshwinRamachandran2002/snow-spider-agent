WITH june_records AS (
    /* 1. keep only one record per country‑date within June 2022 */
    SELECT DISTINCT
           country_code_2,
           DATE(insert_date) AS dt
    FROM cities
    WHERE DATE(insert_date) BETWEEN '2022-06-01' AND '2022-06-30'
),
ordered AS (
    /* 2. order the dates and give each a running number */
    SELECT
           country_code_2,
           dt,
           ROW_NUMBER() OVER (PARTITION BY country_code_2 ORDER BY dt) AS rn,
           julianday(dt) AS jd
    FROM june_records
),
grp_dates AS (
    /* 3. consecutive dates share the same (rn‑jd) value */
    SELECT
           country_code_2,
           dt,
           rn - jd AS grp
    FROM ordered
),
streaks AS (
    /* 4. length of every consecutive‑date streak */
    SELECT
           country_code_2,
           grp,
           COUNT(*) AS streak_len
    FROM grp_dates
    GROUP BY country_code_2, grp
),
best_by_country AS (
    /* 5. longest streak per country */
    SELECT
           country_code_2,
           MAX(streak_len) AS max_streak
    FROM streaks
    GROUP BY country_code_2
),
overall_max AS (
    /* 6. longest streak observed among all countries */
    SELECT MAX(max_streak) AS gmax
    FROM best_by_country
)
SELECT
       country_code_2
FROM best_by_country
WHERE max_streak = (SELECT gmax FROM overall_max);