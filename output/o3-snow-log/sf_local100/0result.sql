/*  Count how many performers are at “Shahrukh-number = 2”
    (acted with someone who acted with Shahrukh Khan,
     but never appeared in a film with Shahrukh himself)  */

WITH srk AS (   -- all rows that belong to Shahrukh Khan
    SELECT DISTINCT TRIM("PID") AS "PID"
    FROM DB_IMDB.DB_IMDB."PERSON"
    WHERE LOWER(TRIM("Name")) LIKE '%shah%'
      AND LOWER(TRIM("Name")) LIKE '%khan%'
),

srk_movies AS (   -- every movie that contains Shahrukh Khan
    SELECT DISTINCT mc."MID"
    FROM DB_IMDB.DB_IMDB."M_CAST" mc
    JOIN srk ON TRIM(mc."PID") = srk."PID"
),

coactors AS (     -- actors who shared a movie with Shahrukh Khan
    SELECT DISTINCT TRIM(mc."PID") AS "PID"
    FROM DB_IMDB.DB_IMDB."M_CAST" mc
    JOIN srk_movies sm ON mc."MID" = sm."MID"
    WHERE TRIM(mc."PID") NOT IN (SELECT "PID" FROM srk)
),

lvl2_movies AS (  -- movies containing a co-actor but NOT Shahrukh Khan
    SELECT DISTINCT mc."MID"
    FROM DB_IMDB.DB_IMDB."M_CAST" mc
    JOIN coactors ca ON TRIM(mc."PID") = ca."PID"
    WHERE mc."MID" NOT IN (SELECT "MID" FROM srk_movies)
),

potential_lvl2_actors AS ( -- everyone who appears in those movies
    SELECT DISTINCT TRIM(mc."PID") AS "PID"
    FROM DB_IMDB.DB_IMDB."M_CAST" mc
    JOIN lvl2_movies lm ON mc."MID" = lm."MID"
),

shahrukh_number_2 AS (    -- keep actors who are neither Shahrukh nor direct co-actors
    SELECT "PID"
    FROM potential_lvl2_actors
    WHERE "PID" NOT IN (SELECT "PID" FROM srk)
      AND "PID" NOT IN (SELECT "PID" FROM coactors)
)

SELECT COUNT(DISTINCT "PID") AS "Shahrukh_Number_2_Count"
FROM shahrukh_number_2;