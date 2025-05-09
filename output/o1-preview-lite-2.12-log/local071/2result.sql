WITH country_dates AS (
  SELECT
    "country_code_2",
    date("insert_date") AS insert_date,
    ROW_NUMBER() OVER (PARTITION BY "country_code_2" ORDER BY date("insert_date")) AS rn
  FROM (
    SELECT DISTINCT "country_code_2", "insert_date"
    FROM "cities"
    WHERE "insert_date" LIKE '2022-06-%'
  )
),
date_groups AS (
  SELECT
    "country_code_2",
    insert_date,
    rn,
    julianday(insert_date) - rn AS grp
  FROM country_dates
),
grouped_dates AS (
  SELECT
    "country_code_2",
    grp,
    COUNT(*) AS streak_length
  FROM date_groups
  GROUP BY "country_code_2", grp
),
max_streaks AS (
  SELECT
    "country_code_2",
    MAX(streak_length) AS max_streak
  FROM grouped_dates
  GROUP BY "country_code_2"
),
max_max_streak AS (
  SELECT MAX(max_streak) AS max_streak_value FROM max_streaks
)
SELECT "country_code_2"
FROM max_streaks
WHERE max_streak = (SELECT max_streak_value FROM max_max_streak);