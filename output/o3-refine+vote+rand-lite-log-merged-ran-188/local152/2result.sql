SELECT
    d."name_id"                           AS director_id,
    n."name"                              AS director_name,
    COUNT(DISTINCT d."movie_id")          AS movie_count,
    ROUND(AVG(m."duration"))              AS avg_inter_movie_duration,
    ROUND(AVG(r."avg_rating"), 2)         AS avg_rating,
    SUM(r."total_votes")                  AS total_votes,
    MIN(r."avg_rating")                   AS min_rating,
    MAX(r."avg_rating")                   AS max_rating,
    SUM(m."duration")                     AS total_movie_duration
FROM "director_mapping" d
JOIN "movies"  m ON m."id"  = d."movie_id"
JOIN "names"   n ON n."id"  = d."name_id"
LEFT JOIN "ratings" r ON r."movie_id" = d."movie_id"
GROUP BY d."name_id", n."name"
ORDER BY movie_count DESC, total_movie_duration DESC
LIMIT 9;