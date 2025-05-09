WITH movie_year AS (
    SELECT 
        "MID",
        CAST(substr("year", length("year")-3, 4) AS INTEGER) AS yr
    FROM Movie
),
movie_cast_gender AS (
    SELECT
        my."MID",
        my.yr,
        SUM(
            CASE 
                WHEN TRIM(Person.Gender) = 'Female' THEN 0        -- female actor
                ELSE 1                                            -- male or unknown
            END
        ) AS non_female_cnt
    FROM movie_year AS my
    LEFT JOIN M_Cast  AS mc   ON TRIM(mc."MID") = TRIM(my."MID")
    LEFT JOIN Person  AS p    ON TRIM(p."PID")  = TRIM(mc."PID")
    LEFT JOIN Person          ON Person.rowid = p.rowid           -- just an alias keeper
    GROUP BY my."MID", my.yr
),
movie_flag AS (
    SELECT
        yr,
        CASE WHEN non_female_cnt = 0 THEN 1 ELSE 0 END AS exclusively_female
    FROM movie_cast_gender
)
SELECT
    yr                                   AS year,
    COUNT(*)                             AS total_movies,
    ROUND(100.0 * SUM(exclusively_female) / COUNT(*), 4) 
                                         AS exclusively_female_percentage
FROM movie_flag
GROUP BY yr
ORDER BY yr;