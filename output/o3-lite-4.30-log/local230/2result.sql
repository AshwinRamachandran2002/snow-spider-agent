WITH high_rated AS (
    SELECT movie_id
    FROM ratings
    WHERE avg_rating > 8
),
top_genres AS (
    SELECT g.genre
    FROM genre AS g
    JOIN high_rated AS h ON h.movie_id = g.movie_id
    GROUP BY g.genre
    ORDER BY COUNT(DISTINCT h.movie_id) DESC
    LIMIT 3
),
qualified_movies AS (
    SELECT DISTINCT h.movie_id
    FROM high_rated AS h
    JOIN genre AS g ON g.movie_id = h.movie_id
    WHERE g.genre IN (SELECT genre FROM top_genres)
),
director_counts AS (
    SELECT n.name                      AS director_name,
           COUNT(DISTINCT dm.movie_id) AS movie_count
    FROM director_mapping AS dm
    JOIN names            AS n  ON n.id = dm.name_id
    WHERE dm.movie_id IN (SELECT movie_id FROM qualified_movies)
    GROUP BY n.name
)
SELECT director_name,
       movie_count
FROM director_counts
ORDER BY movie_count DESC,
         director_name ASC
LIMIT 4;