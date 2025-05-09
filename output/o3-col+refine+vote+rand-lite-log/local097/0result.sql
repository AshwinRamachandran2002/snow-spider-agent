-- Find the 10-year window (start_year … start_year+9) that contains the most movies
SELECT
    s.start_year,
    (
        SELECT COUNT(*)
        FROM Movie m
        WHERE CAST(m.year AS INTEGER) BETWEEN s.start_year AND s.start_year + 9
              AND CAST(m.year AS INTEGER) > 0
    ) AS total_movies
FROM (
        SELECT DISTINCT CAST(year AS INTEGER) AS start_year
        FROM Movie
        WHERE CAST(year AS INTEGER) > 0
     ) AS s
ORDER BY total_movies DESC, start_year
LIMIT 1;