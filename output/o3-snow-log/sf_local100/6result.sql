WITH srk_pids AS (      -- Shahrukh Khan’s own PID(s)
    SELECT DISTINCT "PID"
    FROM DB_IMDB.DB_IMDB.PERSON
    WHERE TRIM("Name") ILIKE '%shah%rukh%khan%'          -- handles variants / leading blanks
),

movies_with_srk AS (    -- every movie that features Shahrukh Khan
    SELECT DISTINCT mc."MID"
    FROM DB_IMDB.DB_IMDB.M_CAST mc
    JOIN srk_pids s
      ON TRIM(mc."PID") = s."PID"
),

first_degree_pids AS (  -- actors who worked directly with Shahrukh Khan
    SELECT DISTINCT TRIM(mc1."PID") AS "PID"
    FROM DB_IMDB.DB_IMDB.M_CAST mc1
    WHERE mc1."MID" IN ( SELECT "MID" FROM movies_with_srk )
      AND TRIM(mc1."PID") NOT IN ( SELECT "PID" FROM srk_pids )
),

movies_of_first_degree AS (   -- movies of those first-degree actors, excluding SRK movies
    SELECT DISTINCT mc2."MID"
    FROM DB_IMDB.DB_IMDB.M_CAST mc2
    WHERE TRIM(mc2."PID") IN ( SELECT "PID" FROM first_degree_pids )
      AND mc2."MID" NOT IN ( SELECT "MID" FROM movies_with_srk )
),

second_degree_pids AS ( -- actors who worked with a first-degree actor but never with SRK himself
    SELECT DISTINCT TRIM(mc3."PID") AS "PID"
    FROM DB_IMDB.DB_IMDB.M_CAST mc3
    WHERE mc3."MID" IN ( SELECT "MID" FROM movies_of_first_degree )
      AND TRIM(mc3."PID") NOT IN ( SELECT "PID" FROM srk_pids )
      AND TRIM(mc3."PID") NOT IN ( SELECT "PID" FROM first_degree_pids )
)

SELECT COUNT(*) AS "shahrukh_number_2_count"
FROM second_degree_pids;