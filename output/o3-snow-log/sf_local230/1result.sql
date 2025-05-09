WITH high_rated_movies AS (           -- movies with an average rating above 8
    SELECT "movie_id"
    FROM IMDB_MOVIES.IMDB_MOVIES.RATINGS
    WHERE "avg_rating" > 8
),

genre_counts AS (                     -- count of high-rated movies per genre
    SELECT g."genre",
           COUNT(DISTINCT g."movie_id") AS high_rated_movie_cnt
    FROM IMDB_MOVIES.IMDB_MOVIES.GENRE g
    JOIN high_rated_movies hr
      ON g."movie_id" = hr."movie_id"
    GROUP BY g."genre"
),

top_three_genres AS (                 -- the three genres with most such movies
    SELECT "genre"
    FROM genre_counts
    ORDER BY high_rated_movie_cnt DESC NULLS LAST, "genre"
    LIMIT 3
),

director_movie_counts AS (            -- number of high-rated movies per director in those genres
    SELECT d."name_id",
           COUNT(DISTINCT d."movie_id") AS movie_cnt
    FROM IMDB_MOVIES.IMDB_MOVIES.DIRECTOR_MAPPING d
    JOIN high_rated_movies hr
      ON d."movie_id" = hr."movie_id"
    JOIN IMDB_MOVIES.IMDB_MOVIES.GENRE g
      ON d."movie_id" = g."movie_id"
    JOIN top_three_genres tg
      ON g."genre" = tg."genre"
    GROUP BY d."name_id"
),

final_directors AS (                  -- attach director names
    SELECT n."name",
           dmc.movie_cnt
    FROM director_movie_counts dmc
    JOIN IMDB_MOVIES.IMDB_MOVIES.NAMES n
      ON dmc."name_id" = n."id"
    ORDER BY dmc.movie_cnt DESC NULLS LAST, n."name"
    LIMIT 4
)

SELECT *
FROM final_directors;