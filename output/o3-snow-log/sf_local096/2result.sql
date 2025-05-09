WITH movie_year AS (        -- movie id with numeric 4–digit year
    SELECT  
        "MID",
        TRY_TO_NUMBER(RIGHT("year", 4)) AS "yr"
    FROM DB_IMDB.DB_IMDB."MOVIE"
),                                                               
cast_gender AS (             -- every cast member with its gender
    SELECT  
        mc."MID",
        p."Gender"
    FROM DB_IMDB.DB_IMDB."M_CAST"   mc
    LEFT JOIN DB_IMDB.DB_IMDB."PERSON" p
           ON TRIM(mc."PID") = TRIM(p."PID")
),                                                                
per_movie AS (               -- flag movies that have ANY non-female cast
    SELECT
        cg."MID",
        MAX(CASE WHEN cg."Gender" = 'Female' THEN 0 ELSE 1 END) AS has_non_female,
        COUNT(*)                                              AS total_cast
    FROM cast_gender cg
    GROUP BY cg."MID"
)                                                                 
SELECT
    my."yr"                                  AS "Year",
    COUNT(DISTINCT my."MID")                 AS "Total_Movies",
    ROUND(
        100.0 * SUM(
            CASE 
                WHEN pm.has_non_female = 0                 -- no male / unknown
                     AND pm.total_cast   > 0               -- at least one actor
                THEN 1 ELSE 0 
            END
        ) / NULLIF(COUNT(DISTINCT my."MID"),0) , 4)        AS "Pct_Exclusively_Female"
FROM movie_year my
LEFT JOIN per_movie pm
       ON my."MID" = pm."MID"
GROUP BY my."yr"
ORDER BY "Year" NULLS LAST;