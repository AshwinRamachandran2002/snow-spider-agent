WITH srk AS (                           -- Shah Rukh Khan himself
    SELECT TRIM("PID") AS pid
    FROM "Person"
    WHERE "Name" LIKE '%Shahrukh%Khan%' 
       OR "Name" LIKE '%Shah Rukh%Khan%'
),
srk_movies AS (                         -- movies featuring SRK
    SELECT DISTINCT "MID"
    FROM "M_Cast"
    WHERE TRIM("PID") IN (SELECT pid FROM srk)
),
direct_costars AS (                     -- actors with Shahrukh-number = 1
    SELECT DISTINCT TRIM("PID") AS pid
    FROM "M_Cast"
    WHERE "MID" IN (SELECT "MID" FROM srk_movies)
      AND TRIM("PID") NOT IN (SELECT pid FROM srk)
),
co_star_movies AS (                     -- movies that feature any direct co-star but NOT SRK
    SELECT DISTINCT "MID"
    FROM "M_Cast"
    WHERE TRIM("PID") IN (SELECT pid FROM direct_costars)
      AND "MID" NOT IN (SELECT "MID" FROM srk_movies)
),
second_degree_actors AS (               -- actors with Shahrukh-number = 2
    SELECT DISTINCT TRIM("PID") AS pid
    FROM "M_Cast"
    WHERE "MID" IN (SELECT "MID" FROM co_star_movies)
      AND TRIM("PID") NOT IN (SELECT pid FROM srk)           -- not SRK
      AND TRIM("PID") NOT IN (SELECT pid FROM direct_costars) -- not number 1 actors
)
SELECT COUNT(*) AS "shahrukh_number_2"
FROM second_degree_actors;