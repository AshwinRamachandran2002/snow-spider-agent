SELECT
    d.name_id                                AS director_id,
    n.name                                   AS director_name,
    COUNT(DISTINCT d.movie_id)               AS movie_count,
    ROUND(AVG(m.duration), 0)                AS avg_movie_duration,
    ROUND(AVG(r.avg_rating), 2)              AS avg_rating,
    SUM(r.total_votes)                       AS total_votes,
    MIN(r.avg_rating)                        AS min_rating,
    MAX(r.avg_rating)                        AS max_rating,
    SUM(m.duration)                          AS total_duration
FROM
    director_mapping AS d
JOIN
    movies  AS m ON d.movie_id = m.id
JOIN
    ratings AS r ON d.movie_id = r.movie_id
JOIN
    names   AS n ON d.name_id  = n.id
GROUP BY
    d.name_id,
    n.name
ORDER BY
    movie_count DESC,
    total_duration DESC
LIMIT 9;