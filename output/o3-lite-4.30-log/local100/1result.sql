WITH
srk AS (
  SELECT TRIM("PID") AS pid
  FROM "Person"
  WHERE LOWER(TRIM("Name")) = 'shah rukh khan'
  LIMIT 1
),
srk_movies AS (
  SELECT DISTINCT "MID"
  FROM "M_Cast"
  WHERE TRIM("PID") = (SELECT pid FROM srk)
),
direct_coactors AS (
  SELECT DISTINCT TRIM("PID") AS pid
  FROM "M_Cast"
  WHERE "MID" IN (SELECT "MID" FROM srk_movies)
    AND TRIM("PID") <> (SELECT pid FROM srk)
),
coactor_movies AS (
  SELECT DISTINCT "MID"
  FROM "M_Cast"
  WHERE TRIM("PID") IN (SELECT pid FROM direct_coactors)
    AND "MID" NOT IN (SELECT "MID" FROM srk_movies)
),
second_degree_actors AS (
  SELECT DISTINCT TRIM("PID") AS pid
  FROM "M_Cast"
  WHERE "MID" IN (SELECT "MID" FROM coactor_movies)
    AND TRIM("PID") NOT IN (SELECT pid FROM srk)
    AND TRIM("PID") NOT IN (SELECT pid FROM direct_coactors)
)
SELECT COUNT(*) AS actors_with_shahrukh_number_2
FROM second_degree_actors;