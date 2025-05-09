WITH high_rated AS (        -- movies with rating > 8
    SELECT movie_id
    FROM ratings
    WHERE avg_rating > 8
),
genre_counts AS (           -- count how many high‑rated movies each genre has
    SELECT g.genre,
           COUNT(DISTINCT g.movie_id) AS movie_cnt
    FROM genre g
    JOIN high_rated h ON h.movie_id = g.movie_id
    GROUP BY g.genre
    ORDER BY movie_cnt DESC, g.genre
    LIMIT 3                 -- keep the three most‑represented genres
),
selected_movies AS (        -- high‑rated movies that belong to those top genres
    SELECT DISTINCT g.movie_id
    FROM genre g
    JOIN genre_counts gc ON gc.genre = g.genre
    JOIN high_rated h ON h.movie_id = g.movie_id
),
director_movie_counts AS (  -- how many such movies each director has
    SELECT dm.name_id,
           COUNT(DISTINCT dm.movie_id) AS movie_count
    FROM director_mapping dm
    JOIN selected_movies sm ON sm.movie_id = dm.movie_id
    GROUP BY dm.name_id
)
SELECT n.name  AS director,
       dmc.movie_count
FROM director_movie_counts dmc
JOIN names n ON n.id = dmc.name_id
ORDER BY dmc.movie_count DESC, n.name
LIMIT 4;                     -- top four directors