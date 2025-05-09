WITH dates_cn_july AS (
    SELECT DISTINCT insert_date
    FROM cities
    WHERE country_code_2 = 'cn'
      AND insert_date LIKE '2021-07%'
),
ordered AS (
    SELECT insert_date,
           julianday(insert_date) - julianday(
               LAG(insert_date) OVER (ORDER BY insert_date)
           ) AS gap
    FROM dates_cn_july
),
grp AS (
    SELECT insert_date,
           SUM(CASE WHEN gap = 1 THEN 0 ELSE 1 END)
               OVER (ORDER BY insert_date) AS grp_id
    FROM ordered
),
streak_len AS (
    SELECT grp_id,
           COUNT(*) AS len_days
    FROM grp
    GROUP BY grp_id
),
extreme_groups AS (
    SELECT grp_id
    FROM streak_len
    WHERE len_days = (SELECT MIN(len_days) FROM streak_len)
       OR len_days = (SELECT MAX(len_days) FROM streak_len)
),
dates_needed AS (
    SELECT insert_date
    FROM grp
    WHERE grp_id IN (SELECT grp_id FROM extreme_groups)
),
one_city_per_date AS (
    SELECT insert_date,
           MIN(city_name) AS city_name
    FROM cities
    WHERE country_code_2 = 'cn'
      AND insert_date LIKE '2021-07%'
    GROUP BY insert_date
)
SELECT d.insert_date,
       UPPER(SUBSTR(c.city_name, 1, 1)) || LOWER(SUBSTR(c.city_name, 2)) AS city_name
FROM dates_needed AS d
JOIN one_city_per_date AS c
  ON d.insert_date = c.insert_date
ORDER BY d.insert_date;