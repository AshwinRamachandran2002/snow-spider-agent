WITH rated8 AS (
    SELECT movie_id
    FROM ratings
    WHERE avg_rating > 8
),
genre_rated AS (
    SELECT g.genre,
           g.movie_id
    FROM genre AS g
    JOIN rated8 AS r
      ON g.movie_id = r.movie_id
),
genre_counts AS (
    SELECT genre,
           COUNT(DISTINCT movie_id) AS movie_cnt
    FROM genre_rated
    GROUP BY genre
    ORDER BY movie_cnt DESC, genre ASC
    LIMIT 3
),
top_genres AS (
    SELECT genre
    FROM genre_counts
),
director_movies AS (
    SELECT DISTINCT dm.name_id,
           dm.movie_id
    FROM director_mapping AS dm
    JOIN rated8 AS r
      ON dm.movie_id = r.movie_id
    JOIN genre AS g
      ON dm.movie_id = g.movie_id
    JOIN top_genres AS tg
      ON g.genre = tg.genre
)
SELECT n.name                    AS director,
       COUNT(DISTINCT dm.movie_id) AS movie_count
FROM director_movies AS dm
JOIN names AS n
  ON dm.name_id = n.id
GROUP BY dm.name_id
ORDER BY movie_count DESC, director ASC
LIMIT 4;