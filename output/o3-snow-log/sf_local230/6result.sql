WITH high_rated AS (                     -- movies with average rating > 8
    SELECT DISTINCT "movie_id"
    FROM "IMDB_MOVIES"."IMDB_MOVIES"."RATINGS"
    WHERE "avg_rating" > 8
),
rated_genres AS (                        -- genres of those high-rated movies
    SELECT g."genre",
           g."movie_id"
    FROM "IMDB_MOVIES"."IMDB_MOVIES"."GENRE" g
    JOIN high_rated h
      ON g."movie_id" = h."movie_id"
),
top_genres AS (                          -- top-3 genres by number of high-rated movies
    SELECT "genre",
           COUNT(DISTINCT "movie_id") AS genre_movie_cnt
    FROM rated_genres
    GROUP BY "genre"
    ORDER BY genre_movie_cnt DESC NULLS LAST
    LIMIT 3
),
movies_in_top_genres AS (                -- high-rated movies that fall in any of the top-3 genres
    SELECT DISTINCT rg."movie_id"
    FROM rated_genres rg
    JOIN top_genres tg
      ON rg."genre" = tg."genre"
),
director_movie_counts AS (               -- directors with counts of those movies
    SELECT d."name_id",
           COUNT(DISTINCT d."movie_id") AS movies_count
    FROM "IMDB_MOVIES"."IMDB_MOVIES"."DIRECTOR_MAPPING" d
    JOIN movies_in_top_genres m
      ON d."movie_id" = m."movie_id"
    GROUP BY d."name_id"
    ORDER BY movies_count DESC NULLS LAST
    LIMIT 4
)
SELECT COALESCE(n."name", dmc."name_id") AS director_name,
       dmc.movies_count
FROM director_movie_counts dmc
LEFT JOIN "IMDB_MOVIES"."IMDB_MOVIES"."NAMES" n
  ON dmc."name_id" = n."id"
ORDER BY dmc.movies_count DESC NULLS LAST,
         director_name;