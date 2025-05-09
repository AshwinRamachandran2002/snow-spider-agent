WITH
rated_movies AS (              -- movies rated strictly above 8
    SELECT movie_id
    FROM ratings
    WHERE avg_rating > 8
),
top_genres AS (                -- top 3 genres by count of such movies
    SELECT g.genre,
           COUNT(*) AS movie_cnt
    FROM genre g
    JOIN rated_movies r ON r.movie_id = g.movie_id
    GROUP BY g.genre
    ORDER BY movie_cnt DESC, g.genre
    LIMIT 3
),
movies_in_top_genres AS (      -- distinct movies that belong to any of those genres
    SELECT DISTINCT r.movie_id
    FROM rated_movies r
    JOIN genre g         ON g.movie_id = r.movie_id
    JOIN top_genres tg   ON tg.genre = g.genre
),
director_counts AS (           -- count how many of those movies each director made
    SELECT dm.name_id,
           COUNT(DISTINCT dm.movie_id) AS num_movies
    FROM director_mapping dm
    JOIN movies_in_top_genres mitg ON mitg.movie_id = dm.movie_id
    GROUP BY dm.name_id
    ORDER BY num_movies DESC, dm.name_id
    LIMIT 4
)
SELECT n.name      AS director,
       dc.num_movies
FROM director_counts dc
JOIN names n ON n.id = dc.name_id
ORDER BY dc.num_movies DESC, director;