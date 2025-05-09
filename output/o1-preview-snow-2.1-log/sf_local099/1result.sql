WITH yash_movies AS (
   SELECT DISTINCT "MID" 
   FROM "DB_IMDB"."DB_IMDB"."M_DIRECTOR" 
   WHERE "PID" = 'nm0007181'
),
actors_with_yash AS (
   SELECT DISTINCT "PID" 
   FROM "DB_IMDB"."DB_IMDB"."M_CAST" 
   WHERE "MID" IN (SELECT "MID" FROM yash_movies)
),
actor_movie_counts AS (
   SELECT c."PID" as "actor_PID", d."PID" as "director_PID", COUNT(DISTINCT c."MID") as "movie_count"
   FROM "DB_IMDB"."DB_IMDB"."M_CAST" c
   JOIN "DB_IMDB"."DB_IMDB"."M_DIRECTOR" d ON c."MID" = d."MID"
   WHERE c."PID" IN (SELECT "PID" FROM actors_with_yash)
   GROUP BY c."PID", d."PID"
),
actor_yash_counts AS (
   SELECT "actor_PID", "movie_count" as "yash_count"
   FROM actor_movie_counts
   WHERE "director_PID" = 'nm0007181'
),
actor_max_other_counts AS (
   SELECT "actor_PID", MAX("movie_count") as "max_other_count"
   FROM actor_movie_counts
   WHERE "director_PID" <> 'nm0007181'
   GROUP BY "actor_PID"
)
SELECT COUNT(*) as "number_of_actors"
FROM (
   SELECT ayc."actor_PID"
   FROM actor_yash_counts ayc
   LEFT JOIN actor_max_other_counts amoc ON ayc."actor_PID" = amoc."actor_PID"
   WHERE ayc."yash_count" > COALESCE(amoc."max_other_count", 0)
)