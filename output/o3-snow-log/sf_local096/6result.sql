WITH movie_years AS (        -- get every movie together with its numeric year
    SELECT
        "MID",
        CAST(SUBSTR("year", -4) AS INTEGER) AS "year_num"
    FROM DB_IMDB.DB_IMDB."MOVIE"
    WHERE "year" IS NOT NULL
), total_movies_by_year AS (  -- total count of movies per year
    SELECT
        "year_num",
        COUNT(DISTINCT "MID")          AS total_movies
    FROM movie_years
    GROUP BY "year_num"
), movie_cast_gender AS (     -- movies whose ENTIRE cast is female
    SELECT
        my."MID",
        my."year_num",
        SUM(
            CASE 
                WHEN p."Gender" = 'Female' THEN 0      -- female → OK
                ELSE 1                                 -- male / none / null → not OK
            END
        ) AS non_female_cnt
    FROM movie_years               my
    JOIN DB_IMDB.DB_IMDB."M_CAST"  mc  ON mc."MID" = my."MID"
    LEFT JOIN DB_IMDB.DB_IMDB."PERSON" p   ON TRIM(p."PID") = TRIM(mc."PID")
    GROUP BY my."MID", my."year_num"
    HAVING non_female_cnt = 0               -- keep only movies with 0 non-female actors
), exclusive_female_movies AS (  -- count such movies per year
    SELECT
        "year_num",
        COUNT(DISTINCT "MID")     AS exclusive_movies
    FROM movie_cast_gender
    GROUP BY "year_num"
)
SELECT
    t."year_num"                                            AS "Year",
    t.total_movies                                          AS total_movies,
    ROUND(
        COALESCE(ef.exclusive_movies, 0) * 100.0 
        / t.total_movies, 4
    )                                                       AS percentage_exclusively_female_movies
FROM total_movies_by_year t
LEFT JOIN exclusive_female_movies ef
       ON t."year_num" = ef."year_num"
ORDER BY "Year" NULLS LAST;