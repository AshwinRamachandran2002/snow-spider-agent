WITH high_rated AS (            -- movies rated strictly above 8.0
    SELECT movie_id
    FROM ratings
    WHERE avg_rating > 8
),
top_genres AS (                  -- the 3 genres containing most of those movies
    SELECT g.genre
    FROM genre AS g
    JOIN high_rated AS hr ON hr.movie_id = g.movie_id
    GROUP BY g.genre
    ORDER BY COUNT(DISTINCT g.movie_id) DESC
    LIMIT 3
),
qualified_movies AS (            -- movies that are (a) >8-rated AND (b) in the top-3 genres
    SELECT DISTINCT hr.movie_id
    FROM high_rated AS hr
    JOIN genre AS g
      ON g.movie_id = hr.movie_id
    WHERE g.genre IN (SELECT genre FROM top_genres)
),
director_counts AS (             -- how many such movies each director has
    SELECT dm.name_id,
           COUNT(DISTINCT dm.movie_id) AS dir_movie_count
    FROM director_mapping AS dm
    JOIN qualified_movies AS qm ON qm.movie_id = dm.movie_id
    GROUP BY dm.name_id
    ORDER BY dir_movie_count DESC
    LIMIT 4
)
SELECT n.name,
       dc.dir_movie_count
FROM director_counts AS dc
JOIN names AS n ON n.id = dc.name_id
ORDER BY dc.dir_movie_count DESC, n.name;