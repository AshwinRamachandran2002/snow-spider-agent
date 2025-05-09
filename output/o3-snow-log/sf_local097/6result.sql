WITH "MOVIE_YEARS" AS (   -- convert year strings to numbers, discarding non-numeric ones
    SELECT
        TRY_TO_NUMBER("year") AS "YEAR_NUM"
    FROM DB_IMDB.DB_IMDB."MOVIE"
), 
"YEARS" AS (               -- every distinct possible period start
    SELECT DISTINCT 
        "YEAR_NUM" AS "START_YEAR"
    FROM "MOVIE_YEARS"
    WHERE "YEAR_NUM" IS NOT NULL
), 
"PERIOD_COUNTS" AS (       -- count films falling in each 10-year window
    SELECT
        y."START_YEAR",
        COUNT(*) AS "FILM_COUNT"
    FROM "YEARS" y
    JOIN "MOVIE_YEARS" m
      ON m."YEAR_NUM" BETWEEN y."START_YEAR" AND y."START_YEAR" + 9
    WHERE m."YEAR_NUM" IS NOT NULL
    GROUP BY y."START_YEAR"
)
SELECT                      -- pick the period with the most films
    "START_YEAR",
    "FILM_COUNT"
FROM "PERIOD_COUNTS"
ORDER BY "FILM_COUNT" DESC NULLS LAST, "START_YEAR"
LIMIT 1;