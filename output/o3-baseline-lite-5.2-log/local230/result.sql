WITH high_rated_movies AS (
    SELECT movie_id
    FROM ratings
    WHERE avg_rating > 8
),
genre_hr AS (
    SELECT g.genre,
           g.movie_id
    FROM genre AS g
    JOIN high_rated_movies AS hr
      ON g.movie_id = hr.movie_id
),
top_three_genres AS (
    SELECT genre
    FROM genre_hr
    GROUP BY genre
    ORDER BY COUNT(DISTINCT movie_id) DESC, genre
    LIMIT 3
),
directors_in_top_genres AS (
    SELECT dm.name_id,
           dm.movie_id
    FROM director_mapping AS dm
    JOIN genre_hr AS gh
      ON dm.movie_id = gh.movie_id
    WHERE gh.genre IN (SELECT genre FROM top_three_genres)
),
director_movie_counts AS (
    SELECT name_id,
           COUNT(DISTINCT movie_id) AS movie_count
    FROM directors_in_top_genres
    GROUP BY name_id
),
director_names AS (
    SELECT n.name AS director,
           dmc.movie_count
    FROM director_movie_counts AS dmc
    JOIN names AS n
      ON n.id = dmc.name_id
)
SELECT director,
       movie_count
FROM director_names
ORDER BY movie_count DESC, director
LIMIT 4;