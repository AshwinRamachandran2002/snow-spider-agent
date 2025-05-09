WITH high_rated_movies AS (          -- movies with rating > 8
    SELECT "movie_id"
    FROM IMDB_MOVIES.IMDB_MOVIES.RATINGS
    WHERE "avg_rating" > 8
),
genre_movies AS (                    -- attach their genres
    SELECT g."genre",
           g."movie_id"
    FROM IMDB_MOVIES.IMDB_MOVIES.GENRE  g
    JOIN high_rated_movies             h  ON g."movie_id" = h."movie_id"
),
top_genres AS (                       -- top 3 genres by count
    SELECT "genre"
    FROM genre_movies
    GROUP BY "genre"
    ORDER BY COUNT(*) DESC NULLS LAST
    LIMIT 3
),
filtered_movies AS (                  -- high-rated movies that belong to the top genres
    SELECT DISTINCT gm."movie_id"
    FROM genre_movies gm
    JOIN top_genres  tg ON gm."genre" = tg."genre"
),
director_counts AS (                  -- count such movies per director
    SELECT d."name_id",
           COUNT(DISTINCT fm."movie_id") AS "movie_count"
    FROM IMDB_MOVIES.IMDB_MOVIES.DIRECTOR_MAPPING d
    JOIN filtered_movies fm ON d."movie_id" = fm."movie_id"
    GROUP BY d."name_id"
)
SELECT n."name"  AS "director",
       dc."movie_count"
FROM director_counts dc
JOIN IMDB_MOVIES.IMDB_MOVIES.NAMES n
     ON dc."name_id" = n."id"
ORDER BY dc."movie_count" DESC NULLS LAST, n."name"
LIMIT 4;