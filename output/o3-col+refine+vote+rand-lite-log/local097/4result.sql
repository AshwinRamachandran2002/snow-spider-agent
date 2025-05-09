SELECT
    CAST(m1.year AS INTEGER) AS start_year,
    (
        SELECT COUNT(*)
        FROM Movie AS m2
        WHERE CAST(m2.year AS INTEGER)
              BETWEEN CAST(m1.year AS INTEGER)
                  AND CAST(m1.year AS INTEGER) + 9
    ) AS total_movies
FROM (SELECT DISTINCT year FROM Movie) AS m1
ORDER BY total_movies DESC, start_year
LIMIT 1;