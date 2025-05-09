WITH high_rated AS (   -- movies with average rating > 8
    SELECT "movie_id"
    FROM "IMDB_MOVIES"."IMDB_MOVIES"."RATINGS"
    WHERE "avg_rating" > 8
),
genre_counts AS (      -- count of such movies per genre
    SELECT g."genre",
           COUNT(*) AS genre_movie_count
    FROM "IMDB_MOVIES"."IMDB_MOVIES"."GENRE" g
    JOIN high_rated hr
      ON g."movie_id" = hr."movie_id"
    GROUP BY g."genre"
),
top_genres AS (        -- top 3 genres by movie count
    SELECT "genre"
    FROM genre_counts
    ORDER BY genre_movie_count DESC NULLS LAST
    LIMIT 3
),
movies_in_top_genres AS (  -- distinct movies that are high-rated AND in the top genres
    SELECT DISTINCT g."movie_id"
    FROM "IMDB_MOVIES"."IMDB_MOVIES"."GENRE" g
    JOIN top_genres tg
      ON g."genre" = tg."genre"
    JOIN high_rated hr
      ON g."movie_id" = hr."movie_id"
),
director_movies AS (   -- directors of those movies
    SELECT dm."name_id",
           dm."movie_id"
    FROM "IMDB_MOVIES"."IMDB_MOVIES"."DIRECTOR_MAPPING" dm
    JOIN movies_in_top_genres mtg
      ON dm."movie_id" = mtg."movie_id"
),
director_counts AS (   -- count distinct movies per director
    SELECT "name_id",
           COUNT(DISTINCT "movie_id") AS movie_count
    FROM director_movies
    GROUP BY "name_id"
    ORDER BY movie_count DESC NULLS LAST
    LIMIT 4
)
SELECT n."name"  AS director_name,
       dc.movie_count
FROM director_counts dc
LEFT JOIN "IMDB_MOVIES"."IMDB_MOVIES"."NAMES" n
       ON dc."name_id" = n."id"
ORDER BY dc.movie_count DESC NULLS LAST,
         director_name;