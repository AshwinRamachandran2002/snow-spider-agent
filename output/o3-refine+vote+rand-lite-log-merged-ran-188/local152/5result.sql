WITH director_movies AS (
    SELECT
        dm.name_id,
        m.id              AS movie_id,
        m.year,
        m.duration,
        r.avg_rating,
        r.total_votes,
        LAG(m.year) OVER (PARTITION BY dm.name_id ORDER BY m.year) AS prev_year
    FROM director_mapping dm
    JOIN movies m          ON dm.movie_id = m.id
    LEFT JOIN ratings r    ON r.movie_id = m.id
),
per_director AS (
    SELECT
        name_id,
        CASE WHEN prev_year IS NULL THEN NULL
             ELSE year - prev_year
        END                              AS year_gap,
        duration,
        avg_rating,
        total_votes
    FROM director_movies
)
SELECT
    pd.name_id                              AS director_id,
    n.name,
    COUNT(*)                                AS movie_count,
    ROUND(AVG(year_gap), 0)                 AS avg_inter_movie_duration,
    ROUND(AVG(avg_rating), 2)               AS avg_rating,
    SUM(total_votes)                        AS total_votes,
    MIN(avg_rating)                         AS min_rating,
    MAX(avg_rating)                         AS max_rating,
    SUM(duration)                           AS total_movie_duration
FROM per_director pd
JOIN names n ON n.id = pd.name_id
GROUP BY pd.name_id, n.name
ORDER BY movie_count DESC,
         total_movie_duration DESC
LIMIT 9;