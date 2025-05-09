WITH ActorYears AS (
    SELECT
        "M_Cast"."PID",
        CAST(SUBSTR("Movie"."year", -4) AS INTEGER) AS "year"
    FROM
        "M_Cast"
    JOIN "Movie" ON "M_Cast"."MID" = "Movie"."MID"
    WHERE
        "Movie"."year" IS NOT NULL
),
UniqueActorYears AS (
    SELECT DISTINCT "PID", "year" FROM ActorYears
),
ActorYearDiffs AS (
    SELECT
        "PID",
        "year",
        LAG("year") OVER (PARTITION BY "PID" ORDER BY "year") AS "prev_year",
        ("year" - LAG("year") OVER (PARTITION BY "PID" ORDER BY "year")) AS "year_diff"
    FROM
        UniqueActorYears
),
MaxYearGaps AS (
    SELECT
        "PID",
        MAX(COALESCE("year_diff", 0)) AS "max_gap"
    FROM
        ActorYearDiffs
    GROUP BY
        "PID"
)
SELECT
    COUNT(*) AS "Number_of_actors"
FROM
    MaxYearGaps
WHERE
    "max_gap" <= 3;