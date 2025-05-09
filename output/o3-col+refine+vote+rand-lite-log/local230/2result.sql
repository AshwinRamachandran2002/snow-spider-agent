WITH high_rated AS (                      -- movies rated > 8
    SELECT movie_id
    FROM ratings
    WHERE avg_rating > 8
),
top_genres AS (                           -- TOP-3 genres by count of such movies
    SELECT g.genre
    FROM genre AS g
    JOIN high_rated AS h ON h.movie_id = g.movie_id
    GROUP BY g.genre
    ORDER BY COUNT(DISTINCT g.movie_id) DESC
    LIMIT 3
),
relevant_movies AS (                      -- movies that are > 8 AND in TOP-3 genres
    SELECT DISTINCT g.movie_id
    FROM genre  AS g
    JOIN high_rated AS h ON h.movie_id = g.movie_id
    WHERE g.genre IN (SELECT genre FROM top_genres)
),
director_counts AS (                      -- count such movies per director
    SELECT d.name_id,
           COUNT(DISTINCT d.movie_id) AS movie_cnt
    FROM director_mapping AS d
    WHERE d.movie_id IN (SELECT movie_id FROM relevant_movies)
    GROUP BY d.name_id
    ORDER BY movie_cnt DESC
    LIMIT 4                               -- TOP-4 directors
)
SELECT n.name        AS director,
       dc.movie_cnt  AS high_rated_movie_count
FROM director_counts AS dc
JOIN names           AS n  ON n.id = dc.name_id
ORDER BY dc.movie_cnt DESC;