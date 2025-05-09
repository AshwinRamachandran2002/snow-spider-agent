WITH YearFilms AS (
    SELECT
        CAST(SUBSTR("year", -4, 4) AS INTEGER) AS "year_numeric",
        COUNT(*) AS "film_count"
    FROM "Movie"
    WHERE
        LENGTH("year") >= 4
        AND SUBSTR("year", -4, 4) GLOB '[0-9][0-9][0-9][0-9]'
        AND CAST(SUBSTR("year", -4, 4) AS INTEGER) BETWEEN 1931 AND 2018
    GROUP BY "year_numeric"
),
TenYearTotals AS (
    SELECT
        YF1.year_numeric AS start_year,
        SUM(YF2.film_count) AS total_films
    FROM YearFilms YF1
    JOIN YearFilms YF2 ON YF2.year_numeric BETWEEN YF1.year_numeric AND YF1.year_numeric + 9
    GROUP BY YF1.year_numeric
)
SELECT start_year, total_films
FROM TenYearTotals
ORDER BY total_films DESC
LIMIT 1;