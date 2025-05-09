WITH movie_year AS (                                   -- extract numeric year for every movie
    SELECT
        "MID",
        TRY_TO_NUMBER(RIGHT("year", 4)) AS "year"
    FROM DB_IMDB.DB_IMDB."MOVIE"
    WHERE RIGHT("year", 4) REGEXP '^[0-9]{4}$'        -- keep rows where last 4 chars are digits
),                                                     -- ------------------------------------------------
movie_cast_summary AS (                               -- summarise gender composition per movie
    SELECT
        MC."MID",
        COUNT(*)                                           AS total_cast,
        SUM( CASE                                          
                WHEN COALESCE(P."Gender",'None') = 'Female' 
                THEN 0 
                ELSE 1 
            END )                                         AS non_female_cast     -- 0 ⇒ exclusively female
    FROM DB_IMDB.DB_IMDB."M_CAST"  MC
    LEFT JOIN DB_IMDB.DB_IMDB."PERSON" P
           ON MC."PID" = P."PID"
    GROUP BY MC."MID"
),                                                     -- ------------------------------------------------
movie_flag AS (                                        -- flag movies that are exclusively-female
    SELECT
        my."year",
        CASE 
            WHEN mcs.total_cast > 0                         -- require at least one actor
                 AND mcs.non_female_cast = 0
            THEN 1
            ELSE 0
        END AS exclusive_female_movie
    FROM movie_year             my
    LEFT JOIN movie_cast_summary mcs
           ON my."MID" = mcs."MID"
)
SELECT
    "year",
    COUNT(*)                                                   AS total_movies,
    ROUND( 100.0 * SUM(exclusive_female_movie) 
           / NULLIF(COUNT(*),0), 4)                           AS pct_exclusively_female_movies
FROM movie_flag
GROUP BY "year"
ORDER BY "year" NULLS LAST;