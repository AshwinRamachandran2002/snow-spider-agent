WITH year_movies AS (
    /* every movie with its (numeric) release year */
    SELECT 
        "MID",
        CAST(substr("year", -4) AS INTEGER) AS yr
    FROM "Movie"
),
/* movies whose whole cast consists solely of female actors                */
/*   – at least one actor, and NO actor whose gender is not 'Female'       */
female_only_movies AS (
    SELECT 
        ym.yr,
        ym."MID"
    FROM year_movies AS ym
    JOIN "M_Cast"  AS mc ON mc."MID" = ym."MID"
    JOIN "Person"  AS p  ON p."PID" = TRIM(mc."PID")
    GROUP BY ym."MID"
    HAVING 
        MAX(CASE WHEN p."Gender" <> 'Female' THEN 1 ELSE 0 END) = 0   /* no non‑female */
        AND
        MAX(CASE WHEN p."Gender"  = 'Female' THEN 1 ELSE 0 END) = 1   /* at least one */
),
/* total movies per year */
totals AS (
    SELECT yr, COUNT(*) AS total_movies
    FROM year_movies
    GROUP BY yr
),
/* female‑only counts per year */
female_only_counts AS (
    SELECT yr, COUNT(*) AS female_only_movies
    FROM female_only_movies
    GROUP BY yr
)
/* final result */
SELECT 
    t.yr          AS year,
    t.total_movies,
    ROUND(
        100.0 * COALESCE(f.female_only_movies, 0) / t.total_movies,
        4
    ) AS exclusive_female_percentage
FROM totals AS t
LEFT JOIN female_only_counts AS f USING (yr)
ORDER BY t.yr;