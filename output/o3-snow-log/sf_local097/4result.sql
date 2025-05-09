WITH movie_years AS (
    SELECT TRY_CAST("year" AS INTEGER) AS "year_int"
    FROM DB_IMDB.DB_IMDB."MOVIE"
    WHERE TRY_CAST("year" AS INTEGER) IS NOT NULL
),
distinct_years AS (
    SELECT DISTINCT "year_int" AS "start_year"
    FROM movie_years
),
period_counts AS (
    SELECT
        dy."start_year",
        (
            SELECT COUNT(*)
            FROM movie_years my
            WHERE my."year_int" BETWEEN dy."start_year" AND dy."start_year" + 9
        ) AS "film_count"
    FROM distinct_years dy
)
SELECT
    "start_year",
    "film_count"
FROM period_counts
QUALIFY RANK() OVER (ORDER BY "film_count" DESC, "start_year" ASC) = 1;