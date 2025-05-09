WITH movie_year AS (
    -- get movie id and numerical year
    SELECT 
        "MID",
        CAST(substr("year", length("year") - 3, 4) AS INTEGER) AS year
    FROM Movie
),
female_only_movies AS (
    -- movies whose entire cast is female (no male or unknown)
    SELECT 
        mc."MID"
    FROM M_Cast mc
    JOIN Person p
      ON mc."PID" = p."PID"
    GROUP BY mc."MID"
    HAVING SUM(                             -- any non‑female actor?
             CASE 
                 WHEN TRIM(IFNULL(p.Gender,'')) = 'Female' THEN 0 
                 ELSE 1 
             END
           ) = 0        -- 0 ⇒ all actors are female
),
year_stats AS (
    -- count totals and female‑only movies per year
    SELECT
        my.year,
        COUNT(*)                              AS total_movies,
        SUM(CASE WHEN fom."MID" IS NOT NULL   -- female‑only flag
                 THEN 1 ELSE 0 END)           AS female_only_movies
    FROM movie_year  my
    LEFT JOIN female_only_movies fom
           ON my."MID" = fom."MID"
    GROUP BY my.year
)
SELECT
    year,
    total_movies,
    ROUND(female_only_movies * 100.0 / total_movies, 4) AS percentage_exclusively_female
FROM year_stats
ORDER BY year;