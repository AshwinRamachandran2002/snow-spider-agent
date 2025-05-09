WITH years AS (
    SELECT DISTINCT TRY_TO_NUMBER("year") AS yr
    FROM DB_IMDB.DB_IMDB.MOVIE
    WHERE TRY_TO_NUMBER("year") IS NOT NULL
),
period_counts AS (
    SELECT
        y.yr AS start_year,
        COUNT(*) AS total_films
    FROM years y
    JOIN DB_IMDB.DB_IMDB.MOVIE m
        ON TRY_TO_NUMBER(m."year") BETWEEN y.yr AND y.yr + 9
    WHERE TRY_TO_NUMBER(m."year") IS NOT NULL
    GROUP BY y.yr
)
SELECT start_year, total_films
FROM period_counts
ORDER BY total_films DESC NULLS LAST, start_year ASC
LIMIT 1;