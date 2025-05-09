WITH high_rating_movies AS (                        -- movies with average rating above 8
    SELECT "movie_id"
    FROM IMDB_MOVIES.IMDB_MOVIES.RATINGS
    WHERE "avg_rating" > 8
),

genre_counts AS (                                   -- number of such movies per genre
    SELECT g."genre",
           COUNT(*) AS movie_cnt
    FROM IMDB_MOVIES.IMDB_MOVIES.GENRE g
    JOIN high_rating_movies h
      ON g."movie_id" = h."movie_id"
    GROUP BY g."genre"
),

top_genres AS (                                     -- three genres with most high-rated movies
    SELECT "genre"
    FROM genre_counts
    ORDER BY movie_cnt DESC NULLS LAST
    LIMIT 3
),

movies_in_top_genres AS (                           -- movies >8 rating within those genres
    SELECT DISTINCT h."movie_id"
    FROM high_rating_movies h
    JOIN IMDB_MOVIES.IMDB_MOVIES.GENRE g
      ON g."movie_id" = h."movie_id"
    JOIN top_genres tg
      ON g."genre" = tg."genre"
),

director_movie_counts AS (                          -- count of such movies per director
    SELECT d."name_id",
           COUNT(DISTINCT d."movie_id") AS movie_cnt
    FROM IMDB_MOVIES.IMDB_MOVIES.DIRECTOR_MAPPING d
    JOIN movies_in_top_genres m
      ON d."movie_id" = m."movie_id"
    GROUP BY d."name_id"
),

director_names AS (                                 -- resolve director IDs to names
    SELECT n."name" AS director,
           dmc.movie_cnt
    FROM director_movie_counts dmc
    JOIN IMDB_MOVIES.IMDB_MOVIES.NAMES n
      ON n."id" = dmc."name_id"
)

SELECT director,
       movie_cnt
FROM director_names
ORDER BY movie_cnt DESC NULLS LAST, director
LIMIT 4;