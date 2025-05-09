WITH srk_movies AS (                              -- all movies featuring Shah Rukh Khan
        SELECT DISTINCT "MID"
        FROM "DB_IMDB"."DB_IMDB"."M_CAST"
        WHERE TRIM("PID") = 'nm0451321'
),
first_degree_actors AS (                          -- every co-actor of SRK
        SELECT DISTINCT TRIM("PID") AS "PID"
        FROM "DB_IMDB"."DB_IMDB"."M_CAST"
        WHERE "MID" IN (SELECT "MID" FROM srk_movies)
          AND TRIM("PID") <> 'nm0451321'
),
second_layer_movies AS (                          -- movies that have any first-degree actor but NOT SRK
        SELECT DISTINCT mc."MID"
        FROM "DB_IMDB"."DB_IMDB"."M_CAST" mc
        WHERE TRIM(mc."PID") IN (SELECT "PID" FROM first_degree_actors)
          AND mc."MID" NOT IN (SELECT "MID" FROM srk_movies)
),
second_degree_actors AS (                         -- actors appearing in those bridge movies
        SELECT DISTINCT TRIM(mc."PID") AS "PID"
        FROM "DB_IMDB"."DB_IMDB"."M_CAST" mc
        WHERE mc."MID" IN (SELECT "MID" FROM second_layer_movies)
          AND TRIM(mc."PID") <> 'nm0451321'            -- not SRK
          AND TRIM(mc."PID") NOT IN (SELECT "PID" FROM first_degree_actors)  -- not first-degree
)
SELECT COUNT(*) AS "num_shahrukh_number_2"        -- final answer
FROM second_degree_actors;