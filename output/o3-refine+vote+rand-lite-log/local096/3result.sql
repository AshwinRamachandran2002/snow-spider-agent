WITH exclusive_female_movies AS (
    /* movies whose cast is made up ONLY of female actors */
    SELECT mc.MID
    FROM M_Cast AS mc
    JOIN Person AS p ON mc.PID = p.PID
    GROUP BY mc.MID
    HAVING SUM(CASE WHEN p.Gender <> 'Female' THEN 1 ELSE 0 END) = 0   -- no male / unknown
       AND COUNT(*) > 0                                                -- at least one actor
),
movie_years AS (
    /* movie id together with its (numeric) release‑year */
    SELECT
        m.MID,
        CAST(substr(m.year, length(m.year) - 3, 4) AS INTEGER) AS yr
    FROM Movie AS m
)
SELECT
    my.yr          AS year,
    COUNT(*)       AS total_movies,
    100.0 * SUM(CASE WHEN ef.MID IS NOT NULL THEN 1 ELSE 0 END) 
          / COUNT(*)  AS percentage_exclusively_female
FROM movie_years AS my
LEFT JOIN exclusive_female_movies AS ef
       ON my.MID = ef.MID
GROUP BY my.yr
ORDER BY my.yr;