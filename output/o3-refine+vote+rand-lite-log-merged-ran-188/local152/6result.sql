WITH director_movies AS (
    SELECT 
        dm.name_id                              AS director_id,
        m.year                                  AS movie_year,
        m.duration                              AS movie_duration,
        r.avg_rating                            AS avg_rating,
        r.total_votes                           AS total_votes
    FROM director_mapping dm
    JOIN movies            m ON m.id  = dm.movie_id
    LEFT JOIN ratings      r ON r.movie_id = m.id
),
year_gaps AS (
    SELECT
        director_id,
        movie_year,
        movie_duration,
        avg_rating,
        total_votes,
        movie_year - LAG(movie_year) OVER (
                       PARTITION BY director_id 
                       ORDER BY movie_year
                  )                            AS year_diff
    FROM director_movies
),
director_stats AS (
    SELECT
        director_id,
        COUNT(*)                              AS movie_count,
        ROUND(AVG(year_diff))                 AS avg_inter_movie_duration,
        ROUND(AVG(avg_rating), 2)             AS avg_rating,
        SUM(COALESCE(total_votes, 0))         AS total_votes,
        ROUND(MIN(avg_rating), 2)             AS min_rating,
        ROUND(MAX(avg_rating), 2)             AS max_rating,
        SUM(movie_duration)                   AS total_movie_duration
    FROM year_gaps
    GROUP BY director_id
)
SELECT
    ds.director_id                AS id,
    n.name,
    ds.movie_count,
    ds.avg_inter_movie_duration,
    ds.avg_rating,
    ds.total_votes,
    ds.min_rating,
    ds.max_rating,
    ds.total_movie_duration
FROM director_stats ds
LEFT JOIN names n ON n.id = ds.director_id
ORDER BY
    ds.movie_count DESC,
    ds.total_movie_duration DESC
LIMIT 9;