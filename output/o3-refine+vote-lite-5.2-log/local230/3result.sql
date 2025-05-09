WITH high_rated_movies AS (
    SELECT movie_id
    FROM ratings
    WHERE avg_rating > 8
),
top_genres AS (
    SELECT g.genre,
           COUNT(DISTINCT g.movie_id) AS movie_count
    FROM genre AS g
    JOIN high_rated_movies AS h 
      ON h.movie_id = g.movie_id
    GROUP BY g.genre
    ORDER BY movie_count DESC, g.genre ASC
    LIMIT 3
),
relevant_movies AS (
    SELECT DISTINCT g.movie_id
    FROM genre AS g
    JOIN top_genres AS tg
      ON tg.genre = g.genre
    JOIN high_rated_movies AS h
      ON h.movie_id = g.movie_id
),
director_movie_counts AS (
    SELECT dm.name_id,
           COUNT(DISTINCT dm.movie_id) AS movie_count
    FROM director_mapping AS dm
    JOIN relevant_movies AS rm
      ON rm.movie_id = dm.movie_id
    GROUP BY dm.name_id
),
top_directors AS (
    SELECT n.name AS director_name,
           dmc.movie_count
    FROM director_movie_counts AS dmc
    JOIN names AS n
      ON n.id = dmc.name_id
    ORDER BY dmc.movie_count DESC, n.name ASC
    LIMIT 4
)
SELECT director_name,
       movie_count
FROM top_directors;