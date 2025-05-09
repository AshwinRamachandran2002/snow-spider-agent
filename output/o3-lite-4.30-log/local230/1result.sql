WITH high_rated AS (
    SELECT movie_id
    FROM ratings
    WHERE avg_rating > 8
),
top_genres AS (
    SELECT g.genre,
           COUNT(DISTINCT g.movie_id) AS cnt
    FROM genre g
    JOIN high_rated hr ON hr.movie_id = g.movie_id
    GROUP BY g.genre
    ORDER BY cnt DESC, g.genre
    LIMIT 3
),
qualified_movies AS (
    SELECT DISTINCT g.movie_id
    FROM genre g
    JOIN top_genres tg ON tg.genre = g.genre
    JOIN high_rated hr ON hr.movie_id = g.movie_id
),
director_counts AS (
    SELECT dm.name_id,
           COUNT(DISTINCT dm.movie_id) AS movie_count
    FROM director_mapping dm
    JOIN qualified_movies qm ON qm.movie_id = dm.movie_id
    GROUP BY dm.name_id
)
SELECT n.name AS director_name,
       dc.movie_count
FROM director_counts dc
JOIN names n ON n.id = dc.name_id
ORDER BY dc.movie_count DESC, director_name
LIMIT 4;