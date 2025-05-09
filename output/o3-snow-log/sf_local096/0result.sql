WITH movie_year AS (   -- 1. list every movie with its numeric year
    SELECT
        m."MID",
        TO_NUMBER(RIGHT(m."year", 4)) AS movie_year
    FROM DB_IMDB.DB_IMDB.MOVIE m
),

movie_flags AS (      -- 2. decide for each movie if its whole cast is exclusively female
    SELECT
        my."MID",
        my.movie_year,
        CASE
            WHEN COUNT(mc."PID") > 0                                          -- the movie has at least one actor
             AND SUM(                                                         -- none of them is male / unknown
                   CASE
                       WHEN p."Gender" IS NULL 
                            OR UPPER(TRIM(p."Gender")) <> 'FEMALE'
                       THEN 1 ELSE 0
                   END
                 ) = 0
            THEN 1                                                            -- exclusively-female cast
            ELSE 0
        END AS female_only
    FROM movie_year          my
    LEFT JOIN DB_IMDB.DB_IMDB.M_CAST   mc  ON mc."MID" = my."MID"
    LEFT JOIN DB_IMDB.DB_IMDB.PERSON   p   ON TRIM(mc."PID") = TRIM(p."PID")
    GROUP BY my."MID", my.movie_year
)

SELECT
    movie_year                                AS "YEAR",
    COUNT(*)                                  AS "TOTAL_MOVIES",
    ROUND(100.0 * SUM(female_only) / COUNT(*), 4) AS "PCT_FEMALE_ONLY"
FROM movie_flags
GROUP BY movie_year
ORDER BY movie_year;