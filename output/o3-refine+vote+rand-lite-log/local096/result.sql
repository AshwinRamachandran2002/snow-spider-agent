WITH MovieYear AS (
    SELECT
        "MID",
        CAST(substr("year", -4) AS INTEGER) AS yr
    FROM "Movie"
),
MovieCastGender AS (
    SELECT
        mc."MID",
        COUNT(*)                                   AS actor_cnt,
        MAX(CASE                                   -- 1 if there is any non‑female (Male/NULL/other)
                WHEN p."Gender" IS NULL
                     OR TRIM(p."Gender") <> 'Female' THEN 1
                ELSE 0
            END)                                  AS has_non_female
    FROM "M_Cast" mc
    LEFT JOIN "Person" p ON p."PID" = mc."PID"
    GROUP BY mc."MID"
),
MovieFlag AS (
    SELECT
        my.yr,
        my."MID",
        CASE
            WHEN mcs.actor_cnt > 0
                 AND mcs.has_non_female = 0 THEN 1
            ELSE 0
        END AS exclusively_female
    FROM MovieYear my
    LEFT JOIN MovieCastGender mcs
           ON mcs."MID" = my."MID"
)
SELECT
    yr   AS year,
    COUNT("MID")                                         AS total_movies,
    ROUND(SUM(exclusively_female) * 100.0 / COUNT("MID"), 4)
                                                         AS percentage_exclusively_female
FROM MovieFlag
GROUP BY yr
ORDER BY yr;