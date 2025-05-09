WITH high_rated AS (                              -- movies with rating > 8
    SELECT  r."movie_id"
    FROM    IMDB_MOVIES.IMDB_MOVIES.RATINGS r
    WHERE   r."avg_rating" > 8
),
movie_genre AS (                                  -- attach genres to those movies
    SELECT  g."movie_id",
            g."genre"
    FROM    IMDB_MOVIES.IMDB_MOVIES.GENRE g
    JOIN    high_rated h
           ON h."movie_id" = g."movie_id"
),
top_genres AS (                                   -- pick the 3 most-frequent genres
    SELECT  mg."genre",
            COUNT(DISTINCT mg."movie_id") AS "movie_cnt"
    FROM    movie_genre mg
    GROUP BY mg."genre"
    ORDER BY "movie_cnt" DESC NULLS LAST
    LIMIT 3
),
qualified_movies AS (                             -- high-rated movies that belong to those genres
    SELECT DISTINCT
            mg."movie_id"
    FROM    movie_genre mg
    JOIN    top_genres tg
           ON tg."genre" = mg."genre"
),
director_counts AS (                              -- tally directors of those movies
    SELECT  n."name"              AS "director",
            COUNT(DISTINCT qm."movie_id") AS "movie_count"
    FROM    qualified_movies  qm
    JOIN    IMDB_MOVIES.IMDB_MOVIES.DIRECTOR_MAPPING dm
           ON dm."movie_id" = qm."movie_id"
    JOIN    IMDB_MOVIES.IMDB_MOVIES.NAMES n
           ON n."id" = dm."name_id"
    GROUP BY n."name"
    ORDER BY "movie_count" DESC NULLS LAST
    LIMIT 4
)
SELECT  "director",
        "movie_count"
FROM    director_counts
ORDER BY "movie_count" DESC NULLS LAST;