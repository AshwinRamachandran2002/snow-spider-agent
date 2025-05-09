WITH shahrukh_pid AS (
    SELECT "PID"
    FROM DB_IMDB.DB_IMDB.PERSON
    WHERE "Name" ILIKE '%shah%rukh%khan%'
       OR "Name" ILIKE '%shahrukh%khan%'
), shahrukh_movies AS (
    SELECT DISTINCT mc."MID"
    FROM DB_IMDB.DB_IMDB.M_CAST mc
    WHERE TRIM(mc."PID") IN (SELECT "PID" FROM shahrukh_pid)
), first_degree AS (
    /* actors who acted WITH Shahrukh Khan */
    SELECT DISTINCT TRIM(mc."PID") AS "PID"
    FROM DB_IMDB.DB_IMDB.M_CAST mc
    WHERE mc."MID" IN (SELECT "MID" FROM shahrukh_movies)
      AND TRIM(mc."PID") NOT IN (SELECT "PID" FROM shahrukh_pid)
), second_layer_movies AS (
    /* movies that feature at least one first-degree actor but NOT Shahrukh Khan */
    SELECT DISTINCT mc."MID"
    FROM DB_IMDB.DB_IMDB.M_CAST mc
    WHERE TRIM(mc."PID") IN (SELECT "PID" FROM first_degree)
      AND mc."MID" NOT IN (SELECT "MID" FROM shahrukh_movies)
), second_degree AS (
    /* actors who appear in those movies, excluding first-degree actors and Shahrukh himself */
    SELECT DISTINCT TRIM(mc."PID") AS "PID"
    FROM DB_IMDB.DB_IMDB.M_CAST mc
    WHERE mc."MID" IN (SELECT "MID" FROM second_layer_movies)
      AND TRIM(mc."PID") NOT IN (SELECT "PID" FROM first_degree)
      AND TRIM(mc."PID") NOT IN (SELECT "PID" FROM shahrukh_pid)
)
SELECT COUNT(*) AS "shahrukh_number_2_count"
FROM second_degree;