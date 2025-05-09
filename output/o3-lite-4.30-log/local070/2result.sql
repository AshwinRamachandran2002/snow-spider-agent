WITH cn_dates AS (
    SELECT DISTINCT insert_date
    FROM cities
    WHERE country_code_2 = 'cn'
      AND insert_date BETWEEN '2021-07-01' AND '2021-07-31'
),
grp_dates AS (
    SELECT insert_date,
           ROW_NUMBER() OVER (ORDER BY insert_date) AS rn,
           julianday(insert_date) - ROW_NUMBER() OVER (ORDER BY insert_date) AS grp
    FROM cn_dates
),
streaks AS (
    SELECT grp,
           COUNT(*) AS streak_len
    FROM grp_dates
    GROUP BY grp
),
extreme_grps AS (
    SELECT grp
    FROM streaks
    WHERE streak_len = (SELECT MAX(streak_len) FROM streaks)
       OR streak_len = (SELECT MIN(streak_len) FROM streaks)
),
dates_to_return AS (
    SELECT insert_date
    FROM grp_dates
    WHERE grp IN (SELECT grp FROM extreme_grps)
),
one_city_per_date AS (
    SELECT d.insert_date,
           MIN(c.city_name) AS city_name
    FROM dates_to_return d
    JOIN cities c
      ON c.insert_date = d.insert_date
     AND c.country_code_2 = 'cn'
    GROUP BY d.insert_date
)
SELECT insert_date AS date,
       UPPER(SUBSTR(city_name, 1, 1)) || LOWER(SUBSTR(city_name, 2)) AS city_name
FROM one_city_per_date
ORDER BY insert_date;