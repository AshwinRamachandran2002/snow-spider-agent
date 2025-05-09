WITH movie_year AS (
    -- extract 4–digit year for every movie
    SELECT 
        "MID",
        CAST(substr("year", -4) AS INTEGER) AS yr
    FROM "Movie"
),
exclusive_female_movies AS (
    -- movies whose casts contain at least one actor
    -- and every actor’s gender is strictly 'Female'
    SELECT my."MID", my.yr
    FROM movie_year AS my
    WHERE EXISTS (        -- at least one credited actor
        SELECT 1
        FROM "M_Cast" mc
        JOIN "Person" p ON mc."PID" = p."PID"
        WHERE mc."MID" = my."MID"
    )
    AND NOT EXISTS (      -- no male / unknown actors
        SELECT 1
        FROM "M_Cast" mc
        JOIN "Person" p ON mc."PID" = p."PID"
        WHERE mc."MID" = my."MID"
          AND (TRIM(p."Gender") <> 'Female' OR TRIM(p."Gender") IS NULL)
    )
),
year_totals AS (
    SELECT yr                AS year,
           COUNT(*)          AS total_movies
    FROM movie_year
    GROUP BY yr
),
year_exclusive AS (
    SELECT yr                AS year,
           COUNT(*)          AS female_only_movies
    FROM exclusive_female_movies
    GROUP BY yr
)
SELECT 
    yt.year,
    yt.total_movies,
    ROUND(
        COALESCE(ye.female_only_movies, 0) * 100.0 / yt.total_movies,
        4
    ) AS exclusively_female_percentage
FROM year_totals yt
LEFT JOIN year_exclusive ye
       ON yt.year = ye.year
ORDER BY yt.year;