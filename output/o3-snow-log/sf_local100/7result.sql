/*  Shahrukh-number = 2
    ----------------------------------------------
    Step-1  shahrukh     : the PID(s) whose trimmed
            PERSON name contains “shah … rukh … khan”.
    Step-2  s_movies     : every movie featuring Shahrukh.
    Step-3  co_actors    : all performers who appeared in
            any Shahrukh movie, excluding Shahrukh himself.
    Step-4  co_movies    : all movies that include at least
            one of those co-actors.
    Step-5  sn2          : performers that act in one of the
            co_movies, while being neither Shahrukh himself
            nor one of the direct co-actors.
    Final   count        : number of distinct actors with a
            Shahrukh-number of 2.
*/
WITH shahrukh AS (
    SELECT TRIM("PID") AS "PID"
    FROM   "DB_IMDB"."DB_IMDB"."PERSON"
    WHERE  LOWER(TRIM("Name")) LIKE '%shah%rukh%khan%'
),
s_movies AS (
    SELECT DISTINCT mc."MID"
    FROM   "DB_IMDB"."DB_IMDB"."M_CAST" mc
    JOIN   shahrukh s
      ON   s."PID" = TRIM(mc."PID")
),
co_actors AS (
    SELECT DISTINCT TRIM(mc."PID") AS "PID"
    FROM   "DB_IMDB"."DB_IMDB"."M_CAST" mc
    WHERE  mc."MID" IN (SELECT "MID" FROM s_movies)
      AND  TRIM(mc."PID") NOT IN (SELECT "PID" FROM shahrukh)
),
co_movies AS (
    SELECT DISTINCT mc."MID"
    FROM   "DB_IMDB"."DB_IMDB"."M_CAST" mc
    WHERE  TRIM(mc."PID") IN (SELECT "PID" FROM co_actors)
),
sn2 AS (
    SELECT DISTINCT TRIM(mc."PID") AS "PID"
    FROM   "DB_IMDB"."DB_IMDB"."M_CAST" mc
    WHERE  mc."MID" IN (SELECT "MID" FROM co_movies)
      AND  TRIM(mc."PID") NOT IN (SELECT "PID" FROM shahrukh)
      AND  TRIM(mc."PID") NOT IN (SELECT "PID" FROM co_actors)
)
SELECT COUNT(*) AS "num_actors_with_shahrukh_number_2"
FROM   sn2;