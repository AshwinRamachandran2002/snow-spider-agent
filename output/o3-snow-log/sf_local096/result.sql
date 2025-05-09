WITH movie_year AS (      /* every movie with its release year (last 4 chars of the "year" column) */
    SELECT 
        "MID",
        TO_NUMBER( RIGHT("year", 4) ) AS "Year"
    FROM DB_IMDB.DB_IMDB.MOVIE
    WHERE RIGHT("year", 4) IS NOT NULL
),                                                          /* cast-level gender statistics per movie */
cast_stats AS (
    SELECT 
        mc."MID",
        COUNT(*)                                                   AS total_cast,
        SUM( CASE 
                 WHEN UPPER(TRIM(p."Gender")) = 'FEMALE' THEN 1 
                 ELSE 0 
             END)                                                  AS female_cast
    FROM DB_IMDB.DB_IMDB.M_CAST     mc
    LEFT JOIN DB_IMDB.DB_IMDB.PERSON p
           ON mc."PID" = p."PID"
    GROUP BY mc."MID"
),                                                          /* movies whose entire credited cast is female */
movies_exclusively_female AS (
    SELECT 
        cs."MID"
    FROM cast_stats cs
    WHERE cs.total_cast > 0
      AND cs.total_cast = cs.female_cast
)
SELECT 
    my."Year",
    COUNT(DISTINCT my."MID")                                                       AS total_movies,
    ROUND(
        ( COUNT(DISTINCT CASE WHEN mef."MID" IS NOT NULL THEN my."MID" END) 
          * 100.0 )
        / NULLIF( COUNT(DISTINCT my."MID"), 0 ), 4)                                AS percentage_exclusively_female
FROM movie_year                my
LEFT JOIN movies_exclusively_female mef
       ON my."MID" = mef."MID"
GROUP BY my."Year"
ORDER BY my."Year" NULLS LAST;