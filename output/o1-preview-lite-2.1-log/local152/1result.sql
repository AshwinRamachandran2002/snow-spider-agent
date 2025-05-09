WITH director_movies AS (
  SELECT
    dm."name_id",
    m."id" AS "movie_id",
    m."date_published",
    m."duration",
    r."avg_rating",
    r."total_votes",
    JULIANDAY(m."date_published") - JULIANDAY(
      LAG(m."date_published") OVER (
        PARTITION BY dm."name_id"
        ORDER BY m."date_published"
      )
    ) AS "diff_days"
  FROM "director_mapping" dm
  JOIN "movies" m ON dm."movie_id" = m."id"
  LEFT JOIN "ratings" r ON m."id" = r."movie_id"
)
SELECT
  dm."name_id" AS "ID",
  n."name" AS "Name",
  COUNT(DISTINCT dm."movie_id") AS "Number_of_Movies",
  ROUND(AVG(dm."diff_days")) AS "Avg_Inter-Movie_Duration",
  ROUND(AVG(dm."avg_rating"), 4) AS "Avg_Rating",
  SUM(COALESCE(dm."total_votes", 0)) AS "Total_Votes",
  ROUND(MIN(dm."avg_rating"), 4) AS "Min_Rating",
  ROUND(MAX(dm."avg_rating"), 4) AS "Max_Rating",
  SUM(dm."duration") AS "Total_Movie_Duration"
FROM director_movies dm
JOIN "names" n ON dm."name_id" = n."id"
GROUP BY dm."name_id", n."name"
ORDER BY "Number_of_Movies" DESC, "Total_Movie_Duration" DESC
LIMIT 9;