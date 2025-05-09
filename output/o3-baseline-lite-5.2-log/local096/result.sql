WITH movie_year AS (
    SELECT 
        "MID",
        CAST(substr("year", -4) AS INTEGER) AS yr
    FROM "Movie"
),
cast_analysis AS (
    SELECT
        mc."MID",
        SUM(CASE 
                WHEN TRIM(p."Gender") = 'Female' THEN 0           -- female → ok
                ELSE 1                                            -- male / none / null → not ok
            END)                      AS non_female_cnt,
        COUNT(*)                      AS cast_cnt
    FROM "M_Cast" mc
    JOIN "Person" p ON mc."PID" = p."PID"
    GROUP BY mc."MID"
),
movie_flag AS (
    SELECT
        my.yr,
        my."MID",
        CASE 
            WHEN ca.cast_cnt > 0                -- at least one actor
                 AND ca.non_female_cnt = 0      -- none are non‑female
            THEN 1
            ELSE 0
        END AS exclusively_female
    FROM movie_year my
    LEFT JOIN cast_analysis ca ON my."MID" = ca."MID"
)
SELECT
    yr                              AS year,
    COUNT(*)                        AS total_movies,
    ROUND(100.0 * SUM(exclusively_female) / COUNT(*), 4) 
                                    AS exclusive_female_percentage
FROM movie_flag
GROUP BY yr
ORDER BY yr;