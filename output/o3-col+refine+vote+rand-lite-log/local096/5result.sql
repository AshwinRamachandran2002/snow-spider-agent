WITH cast_stats AS (
    /* Count gender occurrences per movie (using trimmed PIDs) */
    SELECT mc."MID",
           SUM(CASE WHEN p."Gender" = 'Female' THEN 1 ELSE 0 END)                      AS female_cnt,
           SUM(CASE WHEN p."Gender" = 'Male'   THEN 1 ELSE 0 END)                      AS male_cnt,
           SUM(CASE WHEN p."Gender" IS NULL OR p."Gender" = 'None' THEN 1 ELSE 0 END)  AS unknown_cnt
    FROM "M_Cast"  mc
    JOIN "Person"  p  ON TRIM(mc."PID") = p."PID"
    GROUP BY mc."MID"
),
/* Movies whose casts contain ONLY female actors (no male or unknown) */
female_only AS (
    SELECT "MID"
    FROM cast_stats
    WHERE male_cnt = 0
      AND unknown_cnt = 0
)
SELECT
       yr                       AS year,
       COUNT(*)                 AS total_movies,
       ROUND(
           100.0 * SUM(CASE WHEN fo."MID" IS NOT NULL THEN 1 ELSE 0 END) 
           / COUNT(*), 4
       )                       AS percent_female_only
FROM (
       /* Extract numeric year from Movie.year field */
       SELECT "MID",
              CAST(substr("year", -4) AS INTEGER) AS yr
       FROM   "Movie"
) AS m
LEFT JOIN female_only fo  ON m."MID" = fo."MID"
GROUP BY yr
ORDER BY yr;