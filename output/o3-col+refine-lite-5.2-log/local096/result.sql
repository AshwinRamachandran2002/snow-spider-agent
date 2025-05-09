WITH year_movies AS (
    -- every movie with its release year (last 4 chars of Movie.year)
    SELECT 
        CAST(SUBSTR("year", -4) AS INTEGER) AS "year",
        "MID"
    FROM "Movie"
),
exclusive_female_movies AS (
    -- movies whose casts are 100 % female (no male/unknown‑gender actors)
    SELECT 
        mc."MID"
    FROM "M_Cast"      AS mc
    JOIN "Person"      AS p
         ON TRIM(mc."PID") = p."PID"
    GROUP BY mc."MID"
    HAVING SUM(
               CASE 
                    WHEN TRIM(p."Gender") = 'Female' THEN 0  -- female → OK
                    ELSE 1                                   -- male or unknown → disqualify
               END
           ) = 0               -- keep only movies with zero non‑female actors
)
SELECT
    ym."year",
    COUNT(*)                                                AS "total_movies",
    ROUND(
        100.0 * SUM(
            CASE WHEN ym."MID" IN (SELECT "MID" FROM exclusive_female_movies)
                 THEN 1 ELSE 0 END
        ) / COUNT(*), 
        4                                                   -- keep four decimals
    )                                                      AS "percent_exclusively_female"
FROM year_movies AS ym
GROUP BY ym."year"
ORDER BY ym."year";