WITH rated_above_8 AS (
    -- movies whose average rating is strictly greater than 8
    SELECT movie_id
    FROM ratings
    WHERE avg_rating > 8
),
top_genres AS (
    -- top 3 genres with the most such movies
    SELECT g.genre,
           COUNT(DISTINCT g.movie_id) AS movie_cnt
    FROM genre g
    JOIN rated_above_8 r ON r.movie_id = g.movie_id
    GROUP BY g.genre
    ORDER BY movie_cnt DESC, g.genre
    LIMIT 3
),
director_movies AS (
    -- every (director , movie) pair that:
    --  1. movie is rated > 8
    --  2. movie belongs to one of the top‑3 genres
    SELECT DISTINCT dm.name_id,
           dm.movie_id
    FROM director_mapping dm
    JOIN rated_above_8 r       ON r.movie_id = dm.movie_id
    JOIN genre            g    ON g.movie_id = dm.movie_id
    JOIN top_genres       tg   ON tg.genre = g.genre
),
director_counts AS (
    -- count of qualifying movies per director
    SELECT name_id,
           COUNT(*) AS movie_count
    FROM director_movies
    GROUP BY name_id
)
SELECT n.name  AS director,
       dc.movie_count
FROM director_counts dc
JOIN names n ON n.id = dc.name_id
ORDER BY dc.movie_count DESC, n.name
LIMIT 4;