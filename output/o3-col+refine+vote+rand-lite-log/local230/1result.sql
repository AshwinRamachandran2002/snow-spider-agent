WITH high_rated AS (                 -- movies with rating > 8
    SELECT "movie_id"
    FROM   "ratings"
    WHERE  "avg_rating" > 8
),
top_genres AS (                      -- the 3 genres that appear most among those movies
    SELECT  g."genre"
    FROM    "genre" g
    JOIN    high_rated hr ON hr."movie_id" = g."movie_id"
    GROUP BY g."genre"
    ORDER BY COUNT(DISTINCT g."movie_id") DESC
    LIMIT   3
),
director_counts AS (                 -- count high-rated movies (in the 3 genres) per director
    SELECT  dm."name_id",
            COUNT(DISTINCT dm."movie_id") AS high_rated_movie_cnt
    FROM    "director_mapping" dm
    JOIN    high_rated hr        ON hr."movie_id" = dm."movie_id"
    JOIN    "genre" g            ON g."movie_id"  = dm."movie_id"
    WHERE   g."genre" IN (SELECT "genre" FROM top_genres)
    GROUP BY dm."name_id"
)
SELECT  n."name"  AS director_name,
        dc.high_rated_movie_cnt
FROM    director_counts dc
JOIN    "names" n ON n."id" = dc."name_id"
ORDER BY dc.high_rated_movie_cnt DESC,
         n."name"
LIMIT 4;