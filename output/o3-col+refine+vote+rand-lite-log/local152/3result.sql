WITH director_movies AS (
    SELECT dm."name_id",
           n."name",
           m."id"          AS movie_id,
           m."year",
           m."duration",
           r."avg_rating",
           r."total_votes"
    FROM   "director_mapping" dm
    JOIN   "movies"           m ON dm."movie_id" = m."id"
    JOIN   "names"            n ON dm."name_id" = n."id"
    LEFT   JOIN "ratings"     r ON m."id" = r."movie_id"
),
gaps AS (
    SELECT name_id,
           name,
           movie_id,
           year,
           duration,
           avg_rating,
           total_votes,
           LEAD(year) OVER (PARTITION BY name_id ORDER BY year) - year AS gap_to_next
    FROM   director_movies
),
per_director AS (
    SELECT name_id                               AS director_id,
           name,
           COUNT(*)                              AS movie_count,
           ROUND(AVG(gap_to_next), 0)            AS avg_inter_movie_years,
           ROUND(AVG(avg_rating), 2)             AS avg_rating,
           SUM(total_votes)                      AS total_votes,
           MIN(avg_rating)                       AS min_rating,
           MAX(avg_rating)                       AS max_rating,
           SUM(duration)                         AS total_movie_duration
    FROM   gaps
    GROUP  BY director_id, name
)
SELECT director_id,
       name,
       movie_count,
       avg_inter_movie_years,
       avg_rating,
       total_votes,
       min_rating,
       max_rating,
       total_movie_duration
FROM   per_director
ORDER  BY movie_count DESC,
          total_movie_duration DESC
LIMIT  9;