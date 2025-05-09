WITH years AS (
    SELECT DISTINCT CAST("year" AS INTEGER) AS yr
    FROM "Movie"
    WHERE "year" IS NOT NULL
),
year_window_counts AS (
    SELECT
        yr AS start_year,
        (
            SELECT COUNT(*)
            FROM "Movie" AS m
            WHERE CAST(m."year" AS INTEGER) BETWEEN yr AND yr + 9
        ) AS total_movies
    FROM years
),
best_window AS (
    SELECT start_year, total_movies
    FROM year_window_counts
    ORDER BY total_movies DESC, start_year ASC
    LIMIT 1
)
SELECT start_year, total_movies
FROM best_window;