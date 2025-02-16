-- Task: Could you review our records in June 2022 and, for each country, identify their longest streak of consecutive inserted city dates? Please list the 2-letter length country codes and their maximum streak lengths.

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
)
SELECT
  "country_code_2",
  MAX(streak_length) AS max_streak_length
FROM streaks
GROUP BY "country_code_2"
ORDER BY "country_code_2";