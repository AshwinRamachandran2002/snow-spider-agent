WITH
-- movies whose average rating is above 8
high_rated_movies AS (
    SELECT movie_id
    FROM ratings
    WHERE avg_rating > 8
),

-- top 3 genres that have the most high‑rated movies
top_genres AS (
    SELECT g.genre,
           COUNT(DISTINCT g.movie_id) AS movies_above_8
    FROM genre AS g
    JOIN high_rated_movies AS h
      ON h.movie_id = g.movie_id
    GROUP BY g.genre
    ORDER BY movies_above_8 DESC, g.genre
    LIMIT 3
),

-- count of high‑rated movies (within the top genres) directed by each director
director_high_rated_counts AS (
    SELECT d.name_id,
           COUNT(DISTINCT d.movie_id) AS movie_count
    FROM director_mapping AS d
    JOIN high_rated_movies AS h
      ON h.movie_id = d.movie_id
    JOIN genre AS g
      ON g.movie_id = d.movie_id
    JOIN top_genres AS tg
      ON tg.genre = g.genre
    GROUP BY d.name_id
)

-- final result: top 4 directors with the most such movies
SELECT n.name AS director,
       dh.movie_count
FROM director_high_rated_counts AS dh
JOIN names AS n
  ON n.id = dh.name_id
ORDER BY dh.movie_count DESC, n.name
LIMIT 4;