WITH china AS (
    SELECT insert_date,
           LOWER(city_name) AS city_name
    FROM cities
    WHERE country_code_2 = 'cn'
      AND insert_date BETWEEN '2021-07-01' AND '2021-07-31'
),
distinct_dates AS (
    SELECT DISTINCT insert_date
    FROM china
),
tagged AS (
    SELECT insert_date,
           julianday(insert_date) - ROW_NUMBER() OVER (ORDER BY insert_date) AS grp_id
    FROM distinct_dates
),
streaks AS (
    SELECT grp_id,
           COUNT(*) AS streak_len
    FROM tagged
    GROUP BY grp_id
),
extremes AS (
    SELECT MIN(streak_len) AS min_len,
           MAX(streak_len) AS max_len
    FROM streaks
),
wanted_dates AS (
    SELECT t.insert_date
    FROM tagged t
    JOIN streaks s ON t.grp_id = s.grp_id
    JOIN extremes e
      ON s.streak_len = e.min_len OR s.streak_len = e.max_len
),
one_city AS (
    SELECT wd.insert_date,
           MIN(c.city_name) AS city_name
    FROM wanted_dates wd
    JOIN china c USING (insert_date)
    GROUP BY wd.insert_date
)
SELECT insert_date,
       UPPER(SUBSTR(city_name,1,1)) || LOWER(SUBSTR(city_name,2)) AS city_name
FROM one_city
ORDER BY insert_date;