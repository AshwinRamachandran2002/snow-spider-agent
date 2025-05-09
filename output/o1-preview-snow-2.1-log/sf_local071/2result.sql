WITH dates AS (
  SELECT DISTINCT
    "country_code_2",
    TO_DATE("insert_date", 'YYYY-MM-DD') AS insert_date
  FROM
    "CITY_LEGISLATION"."CITY_LEGISLATION"."CITIES"
  WHERE
    TO_DATE("insert_date", 'YYYY-MM-DD') BETWEEN '2022-06-01' AND '2022-06-30'
),
numbered AS (
  SELECT
    "country_code_2",
    insert_date,
    ROW_NUMBER() OVER (PARTITION BY "country_code_2" ORDER BY insert_date) AS rn,
    DATEDIFF('day', '2022-06-01', insert_date) AS date_serial
  FROM dates
),
grouped AS (
  SELECT
    "country_code_2",
    insert_date,
    rn,
    date_serial,
    (date_serial - rn) AS grp
  FROM numbered
),
sequences AS (
  SELECT
    "country_code_2",
    grp,
    COUNT(*) AS streak_length
  FROM grouped
  GROUP BY
    "country_code_2",
    grp
),
max_streaks AS (
  SELECT
    "country_code_2",
    MAX(streak_length) AS max_streak_length
  FROM sequences
  GROUP BY "country_code_2"
),
max_overall_streak AS (
  SELECT MAX(max_streak_length) AS max_streak_length
  FROM max_streaks
),
countries_with_max_streak AS (
  SELECT
    m."country_code_2"
  FROM
    max_streaks m
    JOIN max_overall_streak o ON m.max_streak_length = o.max_streak_length
)

SELECT
  "country_code_2"
FROM
  countries_with_max_streak;