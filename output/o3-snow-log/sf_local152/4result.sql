WITH director_movies AS (
    SELECT 
        dm."name_id"                                    AS director_id ,
        m."id"                                          AS movie_id ,
        COALESCE(m."duration",0)                        AS duration ,
        COALESCE(r."avg_rating",0)                      AS avg_rating ,
        COALESCE(r."total_votes",0)                     AS total_votes
    FROM IMDB_MOVIES.IMDB_MOVIES.DIRECTOR_MAPPING dm
    JOIN IMDB_MOVIES.IMDB_MOVIES.MOVIES            m  ON dm."movie_id" = m."id"
    LEFT JOIN IMDB_MOVIES.IMDB_MOVIES.RATINGS      r  ON dm."movie_id" = r."movie_id"
),
director_agg AS (
    SELECT
        dm.director_id                                           AS "DIRECTOR_ID",
        n."name"                                                 AS "DIRECTOR_NAME",
        COUNT(DISTINCT dm.movie_id)                              AS "MOVIE_COUNT",
        ROUND(AVG(dm.duration))                                  AS "AVG_MOVIE_DURATION",
        ROUND(AVG(dm.avg_rating),2)                              AS "AVG_RATING",
        SUM(dm.total_votes)                                      AS "TOTAL_VOTES",
        MIN(dm.avg_rating)                                       AS "MIN_RATING",
        MAX(dm.avg_rating)                                       AS "MAX_RATING",
        SUM(dm.duration)                                         AS "TOTAL_MOVIE_DURATION"
    FROM director_movies dm
    JOIN IMDB_MOVIES.IMDB_MOVIES.NAMES n ON dm.director_id = n."id"
    GROUP BY dm.director_id, n."name"
),
top_directors AS (
    SELECT 
        da.*,
        ROW_NUMBER() OVER (ORDER BY da."MOVIE_COUNT" DESC, da."TOTAL_MOVIE_DURATION" DESC) AS rn
    FROM director_agg da
)
SELECT 
    "DIRECTOR_ID",
    "DIRECTOR_NAME",
    "MOVIE_COUNT",
    "AVG_MOVIE_DURATION",
    "AVG_RATING",
    "TOTAL_VOTES",
    "MIN_RATING",
    "MAX_RATING",
    "TOTAL_MOVIE_DURATION"
FROM top_directors
WHERE rn <= 9
ORDER BY "MOVIE_COUNT" DESC NULLS LAST, "TOTAL_MOVIE_DURATION" DESC NULLS LAST;