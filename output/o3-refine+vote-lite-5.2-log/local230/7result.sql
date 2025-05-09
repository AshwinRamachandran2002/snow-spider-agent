WITH rated_movies AS (
    -- Movies whose average rating is above 8
    SELECT movie_id
    FROM ratings
    WHERE avg_rating > 8
),
top_genres AS (
    -- Top 3 genres that have the most such highly‑rated movies
    SELECT g.genre,
           COUNT(DISTINCT g.movie_id) AS movie_cnt
    FROM genre AS g
    JOIN rated_movies AS rm ON rm.movie_id = g.movie_id
    GROUP BY g.genre
    ORDER BY movie_cnt DESC, g.genre ASC
    LIMIT 3
),
movies_in_top_genres AS (
    -- All distinct movies that are (a) rated > 8 and (b) in one of the top 3 genres
    SELECT DISTINCT g.movie_id
    FROM genre AS g
    JOIN top_genres  AS tg ON tg.genre = g.genre
    JOIN rated_movies AS rm ON rm.movie_id = g.movie_id
),
director_counts AS (
    -- Count how many such movies each director has directed
    SELECT n.name                        AS director,
           COUNT(DISTINCT dm.movie_id)   AS movie_count
    FROM director_mapping AS dm
    JOIN names             AS n   ON n.id = dm.name_id
    JOIN movies_in_top_genres AS mtg ON mtg.movie_id = dm.movie_id
    GROUP BY n.name
)
-- Top 4 directors with the highest counts
SELECT director,
       movie_count
FROM director_counts
ORDER BY movie_count DESC, director ASC
LIMIT 4;