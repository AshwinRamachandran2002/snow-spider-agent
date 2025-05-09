WITH ActorMovies AS (
  SELECT "M_Cast"."PID", CAST(SUBSTR("Movie"."year", -4) AS INTEGER) AS "year"
  FROM "M_Cast"
  JOIN "Movie" ON "M_Cast"."MID" = "Movie"."MID"
  WHERE "Movie"."year" IS NOT NULL
    AND LENGTH(SUBSTR("Movie"."year", -4)) = 4
    AND CAST(SUBSTR("Movie"."year", -4) AS INTEGER) IS NOT NULL
  GROUP BY "M_Cast"."PID", "year"
),
OrderedYears AS (
  SELECT "PID", "year",
    ROW_NUMBER() OVER (PARTITION BY "PID" ORDER BY "year") AS "rn"
  FROM ActorMovies
),
YearGaps AS (
  SELECT
    a1."PID",
    a1."year",
    a2."year" AS "next_year",
    (a2."year" - a1."year") AS "gap"
  FROM OrderedYears a1
  LEFT JOIN OrderedYears a2 ON a1."PID" = a2."PID" AND a1."rn" + 1 = a2."rn"
),
MaxGaps AS (
  SELECT "PID", MAX("gap") AS "max_gap"
  FROM YearGaps
  GROUP BY "PID"
)
SELECT COUNT(*) AS "Number_of_actors"
FROM MaxGaps
WHERE "max_gap" <= 3;