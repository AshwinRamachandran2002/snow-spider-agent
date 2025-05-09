WITH director_movies AS (
    SELECT
        dm."name_id" AS name_id,
        n."name" AS name,
        dm."movie_id" AS movie_id,
        m."duration" AS duration,
        m."date_published" AS date_published,
        r."avg_rating" AS avg_rating,
        r."total_votes" AS total_votes
    FROM "director_mapping" dm
    JOIN "names" n ON dm."name_id" = n."id"
    JOIN "movies" m ON dm."movie_id" = m."id"
    LEFT JOIN "ratings" r ON m."id" = r."movie_id"
),
director_stats AS (
    SELECT
        name_id,
        name,
        COUNT(DISTINCT movie_id) AS num_movies,
        SUM(duration) AS total_movie_duration,
        ROUND(AVG(avg_rating), 4) AS avg_rating,
        MIN(avg_rating) AS min_rating,
        MAX(avg_rating) AS max_rating,
        SUM(total_votes) AS total_votes
    FROM director_movies
    GROUP BY name_id, name
),
inter_movie_durations AS (
    SELECT
        name_id,
        ROUND(AVG(inter_movie_duration)) AS avg_inter_movie_duration
    FROM (
        SELECT
            name_id,
            (JULIANDAY(date_published) - LAG(JULIANDAY(date_published)) OVER (
                PARTITION BY name_id
                ORDER BY date_published
            )) AS inter_movie_duration
        FROM director_movies
        WHERE date_published IS NOT NULL
    ) sub
    WHERE inter_movie_duration IS NOT NULL
    GROUP BY name_id
)
SELECT
    ds.name_id AS "ID",
    ds.name AS "Name",
    ds.num_movies AS "Number_of_Movies",
    COALESCE(imd.avg_inter_movie_duration, 0) AS "Avg_Inter-Movie_Duration",
    ds.avg_rating AS "Avg_Rating",
    ds.total_votes AS "Total_Votes",
    ds.min_rating AS "Min_Rating",
    ds.max_rating AS "Max_Rating",
    ds.total_movie_duration AS "Total_Movie_Duration"
FROM director_stats ds
LEFT JOIN inter_movie_durations imd ON ds.name_id = imd.name_id
ORDER BY ds.num_movies DESC, ds.total_movie_duration DESC
LIMIT 9;