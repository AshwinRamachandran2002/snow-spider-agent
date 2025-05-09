WITH female_only AS (
    SELECT mc."MID"
    FROM "M_Cast" mc
    JOIN "Person" p
      ON TRIM(mc."PID") = p."PID"
    GROUP BY mc."MID"
    HAVING SUM(
              CASE
                  WHEN p."Gender" IS NULL 
                       OR p."Gender" <> 'Female' THEN 1
                  ELSE 0
              END
           ) = 0
),
movie_year AS (
    SELECT "MID",
           CAST(SUBSTR("year", -4) AS INTEGER) AS yr
    FROM "Movie"
)
SELECT
    my.yr AS year,
    COUNT(*) AS total_movies,
    ROUND(
        100.0 * SUM(
                    CASE
                        WHEN fo."MID" IS NOT NULL THEN 1
                        ELSE 0
                    END
                 ) / COUNT(*),
        4
    ) AS percentage_exclusively_female
FROM movie_year my
LEFT JOIN female_only fo
  ON fo."MID" = my."MID"
GROUP BY my.yr
ORDER BY my.yr;