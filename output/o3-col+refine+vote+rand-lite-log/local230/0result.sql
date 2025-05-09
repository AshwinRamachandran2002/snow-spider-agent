WITH top_genres AS (          -- 1) three genres having the most movies rated > 8
    SELECT g."genre"
    FROM   "ratings" AS r
    JOIN   "genre"   AS g ON g."movie_id" = r."movie_id"
    WHERE  r."avg_rating" > 8.0
    GROUP  BY g."genre"
    ORDER  BY COUNT(*) DESC
    LIMIT 3
),
director_counts AS (          -- 2) how many such movies each director has in those genres
    SELECT n."name"                            AS director_name,
           COUNT(DISTINCT dm."movie_id")       AS movies_above_8_in_top_genres
    FROM   "director_mapping"  AS dm
    JOIN   "ratings"           AS r  ON r."movie_id" = dm."movie_id"
    JOIN   "genre"             AS g  ON g."movie_id" = dm."movie_id"
    JOIN   "names"             AS n  ON n."id"       = dm."name_id"
    WHERE  r."avg_rating" > 8.0
      AND  g."genre" IN (SELECT "genre" FROM top_genres)
    GROUP  BY n."name"
)
SELECT director_name,
       movies_above_8_in_top_genres
FROM   director_counts
ORDER  BY movies_above_8_in_top_genres DESC,
          director_name                 -- tie-breaker (optional)
LIMIT 4;                                -- 3) top four directors