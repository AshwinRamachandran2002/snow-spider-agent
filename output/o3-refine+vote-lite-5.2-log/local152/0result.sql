WITH director_movies AS (
    SELECT DISTINCT
           dm.name_id AS director_id,
           m.id       AS movie_id,
           m.year     AS year,
           m.duration AS duration,
           r.avg_rating,
           r.total_votes
    FROM director_mapping dm
    JOIN movies m ON m.id = dm.movie_id
    LEFT JOIN ratings r ON r.movie_id = m.id
),
gaps AS (
    SELECT
        director_id,
        year - LAG(year) OVER (PARTITION BY director_id ORDER BY year) AS gap
    FROM director_movies
),
agg AS (
    SELECT
        dm.director_id,
        COUNT(*)                                      AS movie_count,
        SUM(COALESCE(dm.duration,0))                  AS total_movie_duration,
        ROUND(AVG(dm.avg_rating), 2)                  AS avg_rating,
        SUM(COALESCE(dm.total_votes,0))               AS total_votes,
        MIN(dm.avg_rating)                            AS min_rating,
        MAX(dm.avg_rating)                            AS max_rating,
        ROUND((
            SELECT AVG(g.gap)
            FROM gaps g
            WHERE g.director_id = dm.director_id
              AND g.gap IS NOT NULL
        ), 0)                                         AS avg_inter_movie_duration
    FROM director_movies dm
    GROUP BY dm.director_id
)
SELECT
    a.director_id AS id,
    n.name,
    a.movie_count,
    a.avg_inter_movie_duration,
    a.avg_rating,
    a.total_votes,
    a.min_rating,
    a.max_rating,
    a.total_movie_duration
FROM agg a
LEFT JOIN names n ON n.id = a.director_id
ORDER BY a.movie_count DESC, a.total_movie_duration DESC
LIMIT 9;