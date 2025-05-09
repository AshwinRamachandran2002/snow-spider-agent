WITH "YEARS" AS (
    -- collect every distinct movie release year (as integer)
    SELECT DISTINCT
           TRY_TO_NUMBER("year") AS "START_YEAR"
    FROM DB_IMDB.DB_IMDB."MOVIE"
    WHERE TRY_TO_NUMBER("year") IS NOT NULL
), "PERIOD_COUNTS" AS (
    -- for each start year, count all movies released in the 10-year window [year, year+9]
    SELECT
        y."START_YEAR",
        COUNT(*) AS "TOTAL_COUNT"
    FROM "YEARS" y
    JOIN DB_IMDB.DB_IMDB."MOVIE" m
      ON TRY_TO_NUMBER(m."year") BETWEEN y."START_YEAR" AND y."START_YEAR" + 9
    GROUP BY y."START_YEAR"
)
-- pick the window with the largest number of movies
SELECT "START_YEAR", "TOTAL_COUNT"
FROM "PERIOD_COUNTS"
ORDER BY "TOTAL_COUNT" DESC NULLS LAST, "START_YEAR" ASC
LIMIT 1;