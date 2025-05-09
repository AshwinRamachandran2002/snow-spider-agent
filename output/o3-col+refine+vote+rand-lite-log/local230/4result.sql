WITH high_rated AS (          -- movies whose average rating is above 8
    SELECT "movie_id"
    FROM   "ratings"
    WHERE  "avg_rating" > 8
),
genre_counts AS (             -- how many high-rated movies each genre owns
    SELECT g."genre",
           COUNT(*) AS genre_movie_cnt
    FROM   "genre" g
    JOIN   high_rated hr ON g."movie_id" = hr."movie_id"
    GROUP  BY g."genre"
),
top3_genres AS (              -- the Top-3 genres by that count
    SELECT "genre"
    FROM   genre_counts
    ORDER  BY genre_movie_cnt DESC
    LIMIT  3
),
eligible_movies AS (          -- high-rated movies that belong to any of the Top-3 genres
    SELECT DISTINCT g."movie_id"
    FROM   "genre" g
    JOIN   top3_genres t ON g."genre" = t."genre"
    JOIN   high_rated hr ON g."movie_id" = hr."movie_id"
),
director_counts AS (          -- how many such movies each director has
    SELECT d."name_id",
           COUNT(DISTINCT d."movie_id") AS high_rated_movie_count
    FROM   "director_mapping" d
    JOIN   eligible_movies em ON d."movie_id" = em."movie_id"
    GROUP  BY d."name_id"
),
top4_directors AS (           -- the Top-4 directors by that movie count
    SELECT *
    FROM   director_counts
    ORDER  BY high_rated_movie_count DESC
    LIMIT  4
)
SELECT n."name" AS "director_name",
       t."high_rated_movie_count"
FROM   top4_directors t
JOIN   "names" n ON n."id" = t."name_id"
ORDER  BY t."high_rated_movie_count" DESC,
         n."name";