WITH female_only AS (
    /* movies whose casts contain only people marked strictly 'Female' */
    SELECT mc."MID"
    FROM   "M_Cast"  AS mc
    JOIN   "Person"  AS p
           ON TRIM(mc."PID") = TRIM(p."PID")
    GROUP  BY mc."MID"
    HAVING SUM(CASE WHEN p."Gender" <> 'Female' THEN 1 ELSE 0 END) = 0
),
movies_per_year AS (
    SELECT CAST(SUBSTR("year", -4) AS INTEGER) AS yr,
           COUNT(*) AS total_movies
    FROM   "Movie"
    GROUP  BY yr
),
female_only_per_year AS (
    SELECT CAST(SUBSTR(mo."year", -4) AS INTEGER) AS yr,
           COUNT(*) AS female_only_movies
    FROM   "Movie" AS mo
    JOIN   female_only AS fo ON mo."MID" = fo."MID"
    GROUP  BY yr
)
SELECT  mp.yr                                     AS "Year",
        mp.total_movies                           AS "Total_Movies",
        ROUND(COALESCE(fop.female_only_movies,0) * 100.0 
              / mp.total_movies, 4)               AS "Percent_Female_Only"
FROM    movies_per_year        AS mp
LEFT    JOIN female_only_per_year AS fop
       ON mp.yr = fop.yr
ORDER   BY mp.yr;