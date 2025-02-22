-- Task: Review the 'CITIES' table for June 2022 where "insert_date" and "country_code_2" are not null. For each country identified by "country_code_2", determine the longest sequence of consecutive days with city insertions based on "insert_date". Identify and list the 2-letter country codes of the countries with the longest such streak.

WITH dates_per_country AS (
  SELECT
    "country_code_2",
    CAST("insert_date" AS DATE) AS "insert_date",
    DENSE_RANK() OVER (
      PARTITION BY "country_code_2"
      ORDER BY CAST("insert_date" AS DATE)
    ) AS rn,
    DATEDIFF('day', '2022-06-01', CAST("insert_date" AS DATE)) AS day_number,
    DATEDIFF('day', '2022-06-01', CAST("insert_date" AS DATE)) -
      DENSE_RANK() OVER (
        PARTITION BY "country_code_2"
        ORDER BY CAST("insert_date" AS DATE)
      ) AS group_id
  FROM "CITY_LEGISLATION"."CITY_LEGISLATION"."CITIES"
  WHERE CAST("insert_date" AS DATE) >= '2022-06-01'
    AND CAST("insert_date" AS DATE) <= '2022-06-30'
    AND "insert_date" IS NOT NULL
    AND "country_code_2" IS NOT NULL
  GROUP BY "country_code_2", CAST("insert_date" AS DATE)
),
streaks AS (
  SELECT
    "country_code_2",
    COUNT(*) AS streak_length
  FROM dates_per_country
  GROUP BY "country_code_2", group_id
),
max_streaks AS (
  SELECT
    "country_code_2",
    MAX(streak_length) AS max_streak_length
  FROM streaks
  GROUP BY "country_code_2"
),
max_streak_length_overall AS (
  SELECT MAX(max_streak_length) AS max_streak_length
  FROM max_streaks
)
SELECT m."country_code_2"
FROM max_streaks m
JOIN max_streak_length_overall o
  ON m.max_streak_length = o.max_streak_length
ORDER BY m."country_code_2";