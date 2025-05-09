WITH per_movie AS (
    SELECT
        m."MID",
        CAST(SUBSTR(m."year", -4) AS INTEGER)                          AS "yr",
        SUM(CASE WHEN p."Gender" = 'Female' THEN 1 ELSE 0 END)         AS "female_cnt",
        SUM(CASE WHEN p."Gender" <> 'Female' OR p."Gender" IS NULL
                 THEN 1 ELSE 0 END)                                    AS "non_female_cnt"
    FROM "Movie"      AS m
    JOIN "M_Cast"     AS mc  ON m."MID" = mc."MID"
    LEFT JOIN "Person" AS p  ON REPLACE(mc."PID", ' ', '') = REPLACE(p."PID", ' ', '')
    GROUP BY m."MID"
),
per_year AS (
    SELECT
        "yr",
        COUNT(*)                                                                                       AS "total_movies",
        SUM(CASE WHEN "female_cnt" > 0 AND "non_female_cnt" = 0 THEN 1 ELSE 0 END)                     AS "exclusive_female_movies"
    FROM per_movie
    GROUP BY "yr"
)
SELECT
    "yr"                                            AS "year",
    "total_movies",
    ROUND(100.0 * "exclusive_female_movies" / "total_movies", 4) AS "pct_exclusive_female"
FROM per_year
ORDER BY "year";