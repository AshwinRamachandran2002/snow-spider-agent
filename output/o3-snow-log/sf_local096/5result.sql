WITH movie_year AS (          -- 1. keep every movie and extract the numeric year
    SELECT 
        "MID",
        TO_NUMBER(RIGHT("year", 4))  AS year_num
    FROM DB_IMDB.DB_IMDB."MOVIE"
    WHERE TRY_TO_NUMBER(RIGHT("year", 4)) IS NOT NULL
),      
gender_summary AS (           -- 2. for every movie decide whether ANY non-female actor exists
    SELECT
        mc."MID",
        MAX( CASE                       -- 0 = all female, 1 = at least one non-female / unknown
                WHEN p."Gender" = 'Female' THEN 0
                ELSE 1
            END
        ) AS has_non_female
    FROM DB_IMDB.DB_IMDB."M_CAST"  mc
    LEFT JOIN DB_IMDB.DB_IMDB."PERSON" p
           ON mc."PID" = p."PID"
    GROUP BY mc."MID"
),
movie_exclusive AS (          -- 3. mark movies that are “exclusively female”
    SELECT
        my.year_num,
        CASE 
            WHEN COALESCE(gs.has_non_female, 1) = 0 THEN 1  -- all actors female
            ELSE 0                                          -- has male / unknown OR no cast listed
        END AS exclusive_female_flag
    FROM movie_year my
    LEFT JOIN gender_summary gs
           ON my."MID" = gs."MID"
)
SELECT
    year_num                                         AS "Year",
    COUNT(*)                                         AS "Total_Movies",
    ROUND(100.0 * SUM(exclusive_female_flag)
                 / COUNT(*), 4)                      AS "Percentage_Exclusively_Female"
FROM movie_exclusive
GROUP BY year_num
ORDER BY year_num;