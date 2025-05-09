WITH yr_movies AS (
    /* 1. Extract numeric year and keep movie id */
    SELECT 
        "MID",
        TO_NUMBER(RIGHT("year", 4))  AS "yr"
    FROM DB_IMDB.DB_IMDB."MOVIE"
    WHERE "year" IS NOT NULL
), cast_gender AS (
    /* 2. Bring every cast member’s gender */
    SELECT 
        mc."MID",
        p."Gender"
    FROM DB_IMDB.DB_IMDB."M_CAST"   mc
    LEFT JOIN DB_IMDB.DB_IMDB."PERSON" p
           ON mc."PID" = p."PID"
), movie_flags AS (
    /* 3. For each movie, count non-female cast members and total cast members */
    SELECT 
        y."yr",
        y."MID",
        /* any gender different from 'Female' (including NULL / 'None') is non-female */
        SUM(CASE WHEN cg."Gender" = 'Female' THEN 0 ELSE 1 END)  AS non_female_cnt,
        COUNT(cg."Gender")                                        AS total_cast_cnt
    FROM yr_movies y
    LEFT JOIN cast_gender cg
           ON y."MID" = cg."MID"
    GROUP BY y."yr", y."MID"
), per_year AS (
    /* 4. Aggregate by year */
    SELECT
        "yr",
        COUNT(*)                                                        AS total_movies,
        SUM(
            CASE 
                WHEN non_female_cnt = 0          -- no male / unknown actors
                     AND total_cast_cnt > 0      -- at least one actor
                THEN 1 ELSE 0 
            END
        )                                                               AS exclusively_female_movies
    FROM movie_flags
    GROUP BY "yr"
)
SELECT
    "yr"                                                             AS "year",
    total_movies,
    ROUND(exclusively_female_movies * 100.0 / NULLIF(total_movies,0), 4)
                                                                      AS percentage_exclusively_female_movies
FROM per_year
ORDER BY "year" ASC;