SELECT
  FORMAT_TIMESTAMP('%A', pq.creation_date) AS Day_of_week,
  COUNT(*) AS Questions_Asked,
  SUM(
    CASE WHEN EXISTS (
      SELECT 1
      FROM `bigquery-public-data.stackoverflow.posts_answers` AS pa
      WHERE pa.parent_id = pq.id
        AND TIMESTAMP_DIFF(pa.creation_date, pq.creation_date, MINUTE) BETWEEN 0 AND 60
    ) THEN 1 ELSE 0 END
  ) AS Questions_Answered_Within_One_Hour,
  ROUND(
    100 * SUM(
      CASE WHEN EXISTS (
        SELECT 1
        FROM `bigquery-public-data.stackoverflow.posts_answers` AS pa
        WHERE pa.parent_id = pq.id
          AND TIMESTAMP_DIFF(pa.creation_date, pq.creation_date, MINUTE) BETWEEN 0 AND 60
      ) THEN 1 ELSE 0 END
    ) / COUNT(*), 4
  ) AS Percentage_Answered_Within_One_Hour
FROM `bigquery-public-data.stackoverflow.posts_questions` AS pq
WHERE EXTRACT(YEAR FROM pq.creation_date) = 2021
GROUP BY Day_of_week
ORDER BY
  CASE Day_of_week
    WHEN 'Monday' THEN 1
    WHEN 'Tuesday' THEN 2
    WHEN 'Wednesday' THEN 3
    WHEN 'Thursday' THEN 4
    WHEN 'Friday' THEN 5
    WHEN 'Saturday' THEN 6
    WHEN 'Sunday' THEN 7
  END;