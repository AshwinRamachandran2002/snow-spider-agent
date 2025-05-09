SELECT
    dm."name_id"                     AS director_id,
    n."name",
    COUNT(DISTINCT m."id")           AS movie_count,
    ROUND(AVG(m."duration"))         AS avg_inter_movie_duration,
    ROUND(AVG(r."avg_rating"), 2)    AS avg_rating,
    SUM(r."total_votes")             AS total_votes,
    MIN(r."avg_rating")              AS min_rating,
    MAX(r."avg_rating")              AS max_rating,
    SUM(m."duration")                AS total_movie_duration
FROM "director_mapping" AS dm
JOIN "movies"           AS m ON dm."movie_id" = m."id"
LEFT JOIN "ratings"     AS r ON m."id"        = r."movie_id"
JOIN "names"            AS n ON dm."name_id"  = n."id"
GROUP BY dm."name_id"
ORDER BY movie_count DESC,
         total_movie_duration DESC
LIMIT 9;