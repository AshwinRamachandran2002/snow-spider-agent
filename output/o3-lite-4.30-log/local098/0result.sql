WITH valid_movies AS (
    SELECT "MID",
           CAST("year" AS INTEGER) AS yr
    FROM "Movie"
    WHERE "year" GLOB '[0-9][0-9][0-9][0-9]'
),
ordered AS (
    SELECT
        TRIM(mc."PID")                                                AS PID,
        vm.yr                                                         AS yr,
        LEAD(vm.yr) OVER (PARTITION BY TRIM(mc."PID") ORDER BY vm.yr) AS next_yr
    FROM "M_Cast" mc
    JOIN valid_movies vm ON vm."MID" = mc."MID"
),
gaps AS (
    SELECT
        PID,
        MAX(COALESCE(next_yr - yr, 0)) AS max_gap
    FROM ordered
    GROUP BY PID
)
SELECT COUNT(*) AS actor_count
FROM gaps
WHERE max_gap <= 4;