WITH movie_actor_info AS (
    /* collect, for every movie, how many of its cast members are NOT female
       (Male, None or NULL), and the total cast size                               */
    SELECT  m."MID",
            CAST(substr(m."year", -4) AS INTEGER)      AS year,
            COUNT(p."PID")                             AS total_cast,
            SUM( CASE                                   /* count non‑female actors  */
                    WHEN TRIM(COALESCE(p."Gender",'None')) = 'Female' THEN 0
                    ELSE 1
                 END )                                 AS non_female_cnt
    FROM    "Movie"      AS m
    LEFT JOIN "M_Cast"   AS mc ON mc."MID" = m."MID"
    LEFT JOIN "Person"   AS p  ON p."PID"  = mc."PID"
    GROUP BY m."MID"
),
movie_flags AS (
    /* mark each movie: 1 = exclusively‑female cast (and at least one actor), 0 otherwise */
    SELECT  year,
            CASE 
                 WHEN total_cast > 0 AND non_female_cnt = 0 THEN 1
                 ELSE 0
            END AS exclusively_female
    FROM    movie_actor_info
)
SELECT  year,
        COUNT(*)                                            AS total_movies,
        ROUND( 100.0 * SUM(exclusively_female) / COUNT(*), 4) AS exclusively_female_percentage
FROM    movie_flags
GROUP BY year
ORDER BY year;