WITH ActorYears AS (
  SELECT mc."PID", p."Name", CAST(TRY_TO_NUMBER(m."year") AS INT) AS "year"
  FROM "DB_IMDB"."DB_IMDB"."M_CAST" mc
  JOIN "DB_IMDB"."DB_IMDB"."PERSON" p ON TRIM(mc."PID") = TRIM(p."PID")
  JOIN "DB_IMDB"."DB_IMDB"."MOVIE" m ON TRIM(mc."MID") = TRIM(m."MID")
  WHERE mc."PID" IS NOT NULL AND TRIM(mc."PID") <> ''
    AND p."Name" IS NOT NULL AND TRIM(p."Name") <> ''
    AND m."year" IS NOT NULL AND TRIM(m."year") <> ''
    AND TRY_TO_NUMBER(m."year") IS NOT NULL
),
ActorYearDiffs AS (
  SELECT
    "PID",
    "Name",
    "year",
    LAG("year") OVER (PARTITION BY "PID" ORDER BY "year") AS "prev_year",
    "year" - LAG("year") OVER (PARTITION BY "PID" ORDER BY "year") AS "year_diff"
  FROM ActorYears
)
SELECT COUNT(DISTINCT "PID") AS "Number_of_actors_without_long_gap"
FROM (
  SELECT
    "PID",
    "Name",
    COALESCE(MAX("year_diff"), 0) AS "max_gap"
  FROM ActorYearDiffs
  GROUP BY "PID", "Name"
) AS ActorGaps
WHERE "max_gap" < 4