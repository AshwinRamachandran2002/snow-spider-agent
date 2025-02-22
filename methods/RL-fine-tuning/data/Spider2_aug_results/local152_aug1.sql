-- Task: Provide a list of directors with their ID, name, number of movies directed, total movie duration, average rating (rounded to 4 decimal places), minimum rating, maximum rating, and total votes. Order the results by number of movies descending, then by total movie duration descending. Limit the output to 100 rows.

WITH director_movies AS (
    SELECT
        dm."name_id" AS name_id,
        n."name" AS name,
        dm."movie_id" AS movie_id,
        m."duration" AS duration,
        r."avg_rating" AS avg_rating,
        r."total_votes" AS total_votes
    FROM "director_mapping" dm
    JOIN "names" n ON dm."name_id" = n."id"
    JOIN "movies" m ON dm."movie_id" = m."id"
    LEFT JOIN "ratings" r ON m."id" = r."movie_id"
)
SELECT
    name_id AS "ID",
    name AS "Name",
    COUNT(DISTINCT movie_id) AS "Number_of_Movies",
    SUM(duration) AS "Total_Movie_Duration",
    ROUND(AVG(avg_rating), 4) AS "Avg_Rating",
    MIN(avg_rating) AS "Min_Rating",
    MAX(avg_rating) AS "Max_Rating",
    SUM(total_votes) AS "Total_Votes"
FROM director_movies
GROUP BY name_id, name
ORDER BY "Number_of_Movies" DESC, "Total_Movie_Duration" DESC
LIMIT 100;