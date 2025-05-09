/*----------------------------------------------------------
For every movie:
  – pull its release year (last 4 chars of Movie.year)
  – gather all actors attached to that movie
  – count how many of those actors are Female
  – mark the movie as “all-female” only if it has at least
    one cast member AND every cast member is Female
Then, for each year:
  – total number of movies
  – percentage of movies that are “all-female”
----------------------------------------------------------*/
WITH MOVIE_YEAR AS (          -- each movie with numeric year
    SELECT
        "MID",
        TO_NUMBER(RIGHT("year", 4)) AS "YEAR_NUM"
    FROM DB_IMDB.DB_IMDB."MOVIE"
    WHERE "year" IS NOT NULL
),
CAST_GENDER AS (              -- cast gender counts per movie
    SELECT
        mc."MID",
        COUNT(*)                                         AS "TOTAL_CAST",
        COUNT_IF(TRIM(p."Gender") = 'Female')            AS "FEMALE_CAST"
    FROM DB_IMDB.DB_IMDB."M_CAST"   mc
    LEFT JOIN DB_IMDB.DB_IMDB."PERSON" p
           ON mc."PID" = p."PID"
    GROUP BY mc."MID"
),
MOVIE_FLAGS AS (              -- movie flagged if cast is all-female
    SELECT
        my."YEAR_NUM",
        CASE
            WHEN cg."TOTAL_CAST" = cg."FEMALE_CAST"
                 AND cg."TOTAL_CAST" > 0  THEN 1
            ELSE 0
        END  AS "IS_ALL_FEMALE"
    FROM MOVIE_YEAR  my
    LEFT JOIN CAST_GENDER  cg
           ON my."MID" = cg."MID"
)
SELECT
    "YEAR_NUM"                               AS "YEAR",
    COUNT(*)                                 AS "TOTAL_MOVIES",
    ROUND(SUM("IS_ALL_FEMALE") * 100.0
          / NULLIF(COUNT(*),0), 4)           AS "PERCENT_ALL_FEMALE_MOVIES"
FROM MOVIE_FLAGS
GROUP BY "YEAR_NUM"
ORDER BY "YEAR_NUM" NULLS LAST;