SELECT start_year,
       total_films
FROM (
    SELECT  y.start_year,
            (SELECT COUNT(*)
             FROM "Movie" m
             WHERE CAST(m."year" AS INTEGER)
                   BETWEEN y.start_year AND y.start_year + 9) AS total_films
    FROM (
        SELECT DISTINCT CAST("year" AS INTEGER) AS start_year
        FROM "Movie"
    ) y
)
ORDER BY total_films DESC, start_year ASC
LIMIT 1;