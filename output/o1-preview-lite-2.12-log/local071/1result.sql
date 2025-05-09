WITH dates AS (
  SELECT DISTINCT "country_code_2", "insert_date"
  FROM "cities"
  WHERE "insert_date" LIKE '2022-06-%'
),
date_numbers AS (
  SELECT
    "country_code_2",
    "insert_date",
    ROW_NUMBER() OVER (PARTITION BY "country_code_2" ORDER BY "insert_date") AS rn
  FROM dates
),
streaks AS (
  SELECT
    "country_code_2",
    "insert_date",
    rn,
    JULIANDAY("insert_date") - rn AS grp
  FROM date_numbers
),
streak_lengths AS (
  SELECT
    "country_code_2",
    COUNT(*) AS streak_length
  FROM streaks
  GROUP BY "country_code_2", grp
),
max_streaks AS (
  SELECT
    "country_code_2",
    MAX(streak_length) AS max_streak
  FROM streak_lengths
  GROUP BY "country_code_2"
),
longest_streak AS (
  SELECT MAX(max_streak) AS longest_streak
  FROM max_streaks
)
SELECT
  "country_code_2"
FROM
  max_streaks, longest_streak
WHERE
  max_streaks.max_streak = longest_streak.longest_streak;