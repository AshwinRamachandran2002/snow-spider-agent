WITH female_only_movies AS (
    /* Movies whose every credited actor is explicitly marked as Female */
    SELECT m.MID
    FROM Movie AS m
    WHERE NOT EXISTS (
        SELECT 1
        FROM M_Cast AS mc
        LEFT JOIN Person AS p
               ON TRIM(mc.PID) = TRIM(p.PID)
        WHERE mc.MID = m.MID
          AND (p.Gender IS NULL OR TRIM(p.Gender) <> 'Female')
    )
),
totals_per_year AS (
    SELECT CAST(substr(year, length(year) - 3) AS INTEGER) AS year,
           COUNT(*) AS total_movies
    FROM Movie
    GROUP BY year
),
female_only_per_year AS (
    SELECT CAST(substr(m.year, length(m.year) - 3) AS INTEGER) AS year,
           COUNT(*) AS female_only_movies
    FROM Movie AS m
    JOIN female_only_movies AS fo ON fo.MID = m.MID
    GROUP BY year
)
SELECT t.year,
       t.total_movies,
       ROUND(100.0 * COALESCE(f.female_only_movies, 0) / t.total_movies, 4) AS percentage_exclusively_female
FROM totals_per_year AS t
LEFT JOIN female_only_per_year AS f
       ON f.year = t.year
ORDER BY t.year;