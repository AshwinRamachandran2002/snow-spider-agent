WITH cleaned_movie AS (
    SELECT 
        "MID",
        CAST(substr("year", -4) AS INTEGER) AS year
    FROM "Movie"
    WHERE substr("year", -4) GLOB '[0-9][0-9][0-9][0-9]'
),
total_per_year AS (
    SELECT 
        year,
        COUNT(*) AS total_movies
    FROM cleaned_movie
    GROUP BY year
),
female_only_movies AS (
    SELECT 
        m."MID"
    FROM cleaned_movie AS m
    WHERE NOT EXISTS (
        SELECT 1
        FROM "M_Cast" AS c
        LEFT JOIN "Person" AS p
               ON TRIM(c."PID") = TRIM(p."PID")
        WHERE c."MID" = m."MID"
          AND COALESCE(p."Gender", '') <> 'Female'
    )
),
female_per_year AS (
    SELECT 
        cm.year,
        COUNT(*) AS female_only_count
    FROM cleaned_movie AS cm
    JOIN female_only_movies AS f
         ON f."MID" = cm."MID"
    GROUP BY cm.year
)
SELECT 
    t.year,
    t.total_movies,
    printf('%.4f', 1.0 * COALESCE(f.female_only_count, 0) / t.total_movies * 100) 
        AS percentage_exclusively_female
FROM total_per_year AS t
LEFT JOIN female_per_year AS f
       ON t.year = f.year
ORDER BY t.year;