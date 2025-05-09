WITH january AS (
    SELECT *
    FROM "cities"
    WHERE "insert_date" LIKE '2022-01-%'
),
target_country AS (
    SELECT "country_code_2"
    FROM january
    GROUP BY "country_code_2"
    HAVING COUNT(DISTINCT DATE("insert_date")) = 9
),
distinct_dates AS (
    SELECT DISTINCT DATE("insert_date") AS d
    FROM january
    WHERE "country_code_2" IN (SELECT "country_code_2" FROM target_country)
),
ordered AS (
    SELECT d,
           ROW_NUMBER() OVER (ORDER BY d)         AS rn,
           JULIANDAY(d)                           AS jd
    FROM distinct_dates
),
grp AS (
    SELECT d,
           jd - rn                                AS grp_key
    FROM ordered
),
streaks AS (
    SELECT grp_key,
           MIN(d)                                 AS start_date,
           MAX(d)                                 AS end_date,
           COUNT(*)                               AS streak_len
    FROM grp
    GROUP BY grp_key
),
longest AS (
    SELECT *
    FROM streaks
    ORDER BY streak_len DESC, start_date
    LIMIT 1
),
period_rows AS (
    SELECT c.*
    FROM january        AS c
    JOIN target_country AS tc ON c."country_code_2" = tc."country_code_2"
    JOIN longest        AS l  ON DATE(c."insert_date") BETWEEN l.start_date AND l.end_date
)
SELECT
    (SELECT "country_code_2" FROM target_country)         AS country_code,
    (SELECT start_date FROM longest)                      AS start_date,
    (SELECT end_date   FROM longest)                      AS end_date,
    ROUND(
        1.0 * SUM(CASE WHEN "capital" = 1 THEN 1 ELSE 0 END) / COUNT(*),
        4
    )                                                     AS proportion_capital_city_rows
FROM period_rows;