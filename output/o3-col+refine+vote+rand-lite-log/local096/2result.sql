WITH total AS (
    SELECT CAST(SUBSTR("year", -4) AS INTEGER) AS yr,
           COUNT(*) AS total_movies
    FROM "Movie"
    GROUP BY yr
),
female_only_movies AS (
    SELECT CAST(SUBSTR(m."year", -4) AS INTEGER) AS yr,
           m."MID"
    FROM "Movie"     AS m
    JOIN "M_Cast"    AS mc ON mc."MID" = m."MID"
    JOIN "Person"    AS p  ON p."PID" = TRIM(mc."PID")
    GROUP BY m."MID"
    HAVING SUM(CASE WHEN p."Gender" = 'Female' THEN 0 ELSE 1 END) = 0
),
female_per_year AS (
    SELECT yr,
           COUNT(*) AS female_only_count
    FROM female_only_movies
    GROUP BY yr
)
SELECT t.yr AS year,
       t.total_movies,
       ROUND(100.0 * COALESCE(f.female_only_count, 0) / t.total_movies, 2) AS female_only_percentage
FROM total AS t
LEFT JOIN female_per_year AS f ON f.yr = t.yr
ORDER BY t.yr;