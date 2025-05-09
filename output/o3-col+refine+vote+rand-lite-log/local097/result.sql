SELECT
    s.start_year,
    (
        SELECT COUNT(*)
        FROM "Movie" m2
        WHERE CAST(m2."year" AS INTEGER)
              BETWEEN s.start_year AND s.start_year + 9
    ) AS total_movies
FROM (
    SELECT DISTINCT CAST("year" AS INTEGER) AS start_year
    FROM "Movie"
) AS s
ORDER BY total_movies DESC, s.start_year
LIMIT 1;