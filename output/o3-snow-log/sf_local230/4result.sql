WITH high_rated AS (          -- movies with average rating strictly above 8
    SELECT r."movie_id"
    FROM IMDB_MOVIES.IMDB_MOVIES.RATINGS r
    WHERE r."avg_rating" > 8
),

genre_counts AS (             -- count of such movies per genre
    SELECT g."genre",
           COUNT(DISTINCT g."movie_id") AS "movie_count"
    FROM IMDB_MOVIES.IMDB_MOVIES.GENRE g
    JOIN high_rated h
      ON h."movie_id" = g."movie_id"
    GROUP BY g."genre"
),

top_genres AS (               -- top 3 genres with most high-rated movies
    SELECT "genre"
    FROM genre_counts
    ORDER BY "movie_count" DESC NULLS LAST, "genre"
    LIMIT 3
),

director_movie_counts AS (    -- number of high-rated movies (in top genres) per director
    SELECT d."name_id",
           COUNT(DISTINCT d."movie_id") AS "movie_count"
    FROM high_rated h
    JOIN IMDB_MOVIES.IMDB_MOVIES.GENRE g
      ON h."movie_id" = g."movie_id"
    JOIN top_genres tg
      ON g."genre" = tg."genre"
    JOIN IMDB_MOVIES.IMDB_MOVIES.DIRECTOR_MAPPING d
      ON h."movie_id" = d."movie_id"
    GROUP BY d."name_id"
),

top_directors AS (            -- top 4 directors by such movie counts
    SELECT n."name"  AS "director_name",
           dmc."movie_count"
    FROM director_movie_counts dmc
    JOIN IMDB_MOVIES.IMDB_MOVIES.NAMES n
      ON n."id" = dmc."name_id"
    ORDER BY dmc."movie_count" DESC NULLS LAST, "director_name"
    LIMIT 4
)

SELECT *
FROM top_directors;