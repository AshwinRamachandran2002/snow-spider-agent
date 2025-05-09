WITH city_dates AS (
  SELECT
    LOWER(c."city_name") AS "city_name",
    TRY_TO_DATE(c."insert_date", 'YYYY-MM-DD') AS date
  FROM
    CITY_LEGISLATION.CITY_LEGISLATION.CITIES c
  WHERE
    LOWER(c."city_name") IN (
      'beijing', 'shanghai', 'guangzhou', 'shenzhen', 'chengdu',
      'chongqing', 'tianjin', 'wuhan', 'xian', 'nanjing', 'hangzhou'
    )
    AND c."insert_date" IS NOT NULL
),
cte AS (
  SELECT
    cd."city_name",
    cd.date,
    ROW_NUMBER() OVER (PARTITION BY cd."city_name" ORDER BY cd.date) AS rn,
    DATEADD('day', -ROW_NUMBER() OVER (PARTITION BY cd."city_name" ORDER BY cd.date), cd.date) AS grp
  FROM city_dates cd
),
streaks AS (
  SELECT
    cte."city_name",
    cte.grp,
    MIN(cte.date) AS start_date,
    MAX(cte.date) AS end_date,
    COUNT(*) AS streak_length
  FROM cte
  GROUP BY cte."city_name", cte.grp
),
stats AS (
  SELECT
    MAX(streak_length) AS max_streak_length,
    MIN(streak_length) AS min_streak_length
  FROM streaks
),
selected_streaks AS (
  SELECT s.*
  FROM streaks s
  JOIN stats ON s.streak_length = stats.max_streak_length OR s.streak_length = stats.min_streak_length
)
SELECT
  TO_CHAR(cte.date, 'YYYY-MM-DD') AS "Date",
  INITCAP(cte."city_name") AS "City_Name"
FROM cte
JOIN selected_streaks s ON cte."city_name" = s."city_name" AND cte.grp = s.grp
ORDER BY s.streak_length DESC NULLS LAST, INITCAP(cte."city_name"), cte.date;