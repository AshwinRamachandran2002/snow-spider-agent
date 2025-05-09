WITH all_female_movies AS (          -- movies whose cast is exclusively female
    SELECT mc."MID"
    FROM   "M_Cast"  AS mc
    JOIN   "Person"  AS p
           ON p."PID" = TRIM(mc."PID")
    GROUP BY mc."MID"
    HAVING SUM(CASE WHEN p."Gender" = 'Female' THEN 0 ELSE 1 END) = 0
),
year_totals AS (                     -- total movies per year
    SELECT CAST(substr(m."year", -4, 4) AS INTEGER) AS year,
           COUNT(*)                                   AS total_movies
    FROM   "Movie" AS m
    GROUP BY year
),
year_female_only AS (                -- all-female movies per year
    SELECT CAST(substr(m."year", -4, 4) AS INTEGER) AS year,
           COUNT(*)                                   AS female_only_movies
    FROM   "Movie" AS m
    WHERE  m."MID" IN (SELECT "MID" FROM all_female_movies)
    GROUP BY year
)
SELECT yt.year,
       yt.total_movies,
       ROUND(100.0 * COALESCE(yf.female_only_movies, 0) / yt.total_movies, 4) AS pct_all_female
FROM   year_totals       AS yt
LEFT   JOIN year_female_only AS yf
       ON yt.year = yf.year
ORDER  BY yt.year;