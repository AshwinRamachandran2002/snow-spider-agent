WITH only_female AS (
    /* movies whose casts consist solely of actors whose gender = 'Female' */
    SELECT mc."MID"
    FROM   "M_Cast" AS mc
    JOIN   "Person" AS p
           ON TRIM(mc."PID") = p."PID"
    GROUP  BY mc."MID"
    HAVING MAX(CASE WHEN p."Gender" = 'Female' THEN 0 ELSE 1 END) = 0
),
total_per_year AS (
    /* total movies released each year */
    SELECT CAST(SUBSTR("year", -4) AS INTEGER) AS rel_year,
           COUNT(*) AS total_movies
    FROM   "Movie"
    GROUP  BY rel_year
),
female_per_year AS (
    /* count of exclusively-female-cast movies each year */
    SELECT CAST(SUBSTR(m."year", -4) AS INTEGER) AS rel_year,
           COUNT(*) AS female_only_movies
    FROM   "Movie" AS m
    JOIN   only_female AS f
           ON m."MID" = f."MID"
    GROUP  BY rel_year
)
SELECT t.rel_year               AS year,
       t.total_movies,
       ROUND(
           100.0 * COALESCE(f.female_only_movies, 0) / t.total_movies,
           4
       )                        AS female_only_percentage
FROM   total_per_year AS t
LEFT   JOIN female_per_year AS f
       USING (rel_year)
ORDER  BY t.rel_year;