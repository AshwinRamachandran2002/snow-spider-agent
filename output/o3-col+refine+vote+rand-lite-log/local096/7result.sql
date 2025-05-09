/* Year-by-year percentage of movies whose cast is exclusively female */
SELECT  yr                                            AS year,
        COUNT(*)                                      AS total_movies,
        ROUND(100.0 *
              SUM(CASE WHEN exclusively_female = 1 THEN 1 ELSE 0 END)
              / COUNT(*), 4)                          AS exclusive_female_percentage
FROM   (
        /* Mark each movie with an exclusively-female flag (1/0) */
        SELECT  m."MID",
                CAST(substr(m."year", length(m."year") - 3, 4) AS INTEGER)  AS yr,
                COALESCE(ef.exclusively_female, 0)             AS exclusively_female
        FROM    "Movie" AS m
        LEFT JOIN (
                   SELECT  mc."MID",
                           CASE
                               WHEN SUM(CASE WHEN p."Gender" = 'Female' THEN 1 ELSE 0 END) > 0
                                AND SUM(CASE WHEN p."Gender" != 'Female'
                                              OR p."Gender" = ''
                                              OR p."Gender" IS NULL THEN 1 ELSE 0 END) = 0
                               THEN 1 ELSE 0
                           END                                  AS exclusively_female
                   FROM   "M_Cast"  AS mc
                   JOIN   "Person"  AS p
                          ON TRIM(mc."PID") = TRIM(p."PID")
                   GROUP  BY mc."MID"
                 ) AS ef
               ON m."MID" = ef."MID"
      ) AS t
GROUP BY yr
ORDER BY yr;