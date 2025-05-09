WITH years AS (
    SELECT DISTINCT CAST("year" AS INTEGER) AS yr
    FROM "Movie"
    WHERE "year" GLOB '[0-9]*'
), period_counts AS (
    SELECT yr AS start_year,
           (SELECT COUNT(*)
            FROM "Movie"
            WHERE CAST("year" AS INTEGER) BETWEEN yr AND yr + 9) AS total_films
    FROM years
)
SELECT start_year, total_films
FROM period_counts
ORDER BY total_films DESC, start_year
LIMIT 1;