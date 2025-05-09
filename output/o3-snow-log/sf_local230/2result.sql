WITH high_rated AS (   -- movies whose average rating is above 8
    SELECT "movie_id"
    FROM IMDB_MOVIES.IMDB_MOVIES.RATINGS
    WHERE "avg_rating" > 8
),
genre_ranked AS (      -- count such movies per genre and rank them
    SELECT 
        g."genre",
        COUNT(*)                            AS movie_cnt,
        ROW_NUMBER() OVER (ORDER BY COUNT(*) DESC) AS rn
    FROM IMDB_MOVIES.IMDB_MOVIES.GENRE g
    JOIN high_rated h
      ON g."movie_id" = h."movie_id"
    GROUP BY g."genre"
),
top_genres AS (        -- keep only the top-3 genres
    SELECT "genre"
    FROM genre_ranked
    WHERE rn <= 3
),
directors_in_top_genres AS (   -- movies above 8 that fall in any of the top-3 genres
    SELECT 
        dm."name_id",
        COUNT(DISTINCT dm."movie_id") AS movie_cnt
    FROM IMDB_MOVIES.IMDB_MOVIES.DIRECTOR_MAPPING dm
    JOIN high_rated h
      ON dm."movie_id" = h."movie_id"
    JOIN IMDB_MOVIES.IMDB_MOVIES.GENRE g
      ON g."movie_id" = dm."movie_id"
    JOIN top_genres tg
      ON g."genre" = tg."genre"
    GROUP BY dm."name_id"
)
SELECT 
    n."name" AS director,
    d.movie_cnt
FROM directors_in_top_genres d
JOIN IMDB_MOVIES.IMDB_MOVIES.NAMES n
  ON n."id" = d."name_id"
ORDER BY d.movie_cnt DESC NULLS LAST, director
LIMIT 4;