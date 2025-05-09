WITH movies_with_year AS (
    SELECT
        "MID",
        CAST(substr("year", -4) AS INTEGER) AS yr
    FROM "Movie"
),
exclusive_female_movies AS (
    /* movies whose entire credited cast is female (and have at least one actor) */
    SELECT m."MID"
    FROM movies_with_year m
    WHERE EXISTS (      -- at least one credited actor
        SELECT 1
        FROM "M_Cast" mc
        JOIN "Person"  p ON p."PID" = mc."PID"
        WHERE mc."MID" = m."MID"
    )
    AND NOT EXISTS (    -- no actor that is not explicitly female
        SELECT 1
        FROM "M_Cast" mc
        JOIN "Person"  p ON p."PID" = mc."PID"
        WHERE mc."MID" = m."MID"
          AND TRIM(COALESCE(p."Gender",'None')) <> 'Female'
    )
)
SELECT
    mw.yr                       AS year,
    COUNT(*)                    AS total_movies,
    ROUND(
        100.0 * SUM(CASE WHEN ef."MID" IS NOT NULL THEN 1 ELSE 0 END) / COUNT(*),
        4
    )                           AS percentage_exclusively_female
FROM movies_with_year mw
LEFT JOIN exclusive_female_movies ef ON mw."MID" = ef."MID"
GROUP BY mw.yr
ORDER BY mw.yr;