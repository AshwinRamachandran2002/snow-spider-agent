WITH per_movie AS (
    SELECT
        m."MID",
        CAST(SUBSTR(m."year", -4, 4) AS INTEGER) AS movie_year,
        CASE
            WHEN COUNT(mc."PID") = 0 THEN 0                                            -- no cast data ⇒ not exclusively female
            WHEN SUM(CASE WHEN COALESCE(p."Gender", '') = 'Female' THEN 0 ELSE 1 END) = 0
                 THEN 1                                                               -- all listed actors are female
            ELSE 0
        END AS exclusively_female
    FROM "Movie"      AS m
    LEFT JOIN "M_Cast" AS mc ON m."MID" = mc."MID"
    LEFT JOIN "Person" AS p  ON TRIM(mc."PID") = p."PID"
    GROUP BY m."MID"
)
SELECT
    movie_year                AS year,
    COUNT(*)                  AS total_movies,
    ROUND(100.0 * SUM(exclusively_female) / COUNT(*), 4) AS exclusively_female_percentage
FROM per_movie
GROUP BY movie_year
ORDER BY movie_year;