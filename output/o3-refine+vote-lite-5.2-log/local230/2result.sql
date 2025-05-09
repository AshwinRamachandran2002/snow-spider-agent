WITH high_rated AS (          -- movies rated above 8
    SELECT movie_id
    FROM ratings
    WHERE avg_rating > 8
),
genre_counts AS (             -- how many such movies per genre
    SELECT g.genre,
           COUNT(DISTINCT g.movie_id) AS movie_cnt
    FROM genre AS g
    JOIN high_rated AS h ON h.movie_id = g.movie_id
    GROUP BY g.genre
    ORDER BY movie_cnt DESC, g.genre
    LIMIT 3                   -- the 3 most‑represented genres
),
selected_movies AS (          -- high‑rated movies that belong to any of those 3 genres
    SELECT DISTINCT g.movie_id
    FROM genre  AS g
    JOIN high_rated AS h ON h.movie_id = g.movie_id
    WHERE g.genre IN (SELECT genre FROM genre_counts)
),
director_movie_totals AS (    -- how many of those movies each director has
    SELECT dm.name_id        AS director_id,
           COUNT(DISTINCT dm.movie_id) AS movie_cnt
    FROM director_mapping AS dm
    JOIN selected_movies  AS sm ON sm.movie_id = dm.movie_id
    GROUP BY dm.name_id
),
top_directors AS (            -- the 4 directors with the largest counts
    SELECT *
    FROM director_movie_totals
    ORDER BY movie_cnt DESC, director_id
    LIMIT 4
)
SELECT n.name  AS director_name,
       td.movie_cnt AS movie_count
FROM top_directors AS td
LEFT JOIN names AS n
       ON n.id = td.director_id
ORDER BY td.movie_cnt DESC, director_name;