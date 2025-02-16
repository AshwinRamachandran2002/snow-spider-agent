-- Task: Retrieve up to 100 distinct object IDs, titles, and formatted metadata dates (as strings in 'YYYY-MM-DD' format) for objects in the 'The Libraries' department whose titles contain the word 'book', and where the confidence value of their crop hints (from unnesting the 'cropHintsAnnotation.cropHints' field in the 'vision_api_data' table) is greater than 0.5. Order the results by metadata date in descending order.
SELECT DISTINCT o.`object_id`,
                o.`title`,
                FORMAT_DATE('%Y-%m-%d', DATE(o.`metadata_date`)) AS metadata_date
FROM `bigquery-public-data.the_met.objects` AS o
INNER JOIN `bigquery-public-data.the_met.vision_api_data` AS v
  ON o.`object_id` = v.`object_id`
CROSS JOIN UNNEST(v.`cropHintsAnnotation`.cropHints) AS cropHint
WHERE o.`department` = 'The Libraries'
  AND o.`title` LIKE '%book%'
  AND cropHint.confidence > 0.5
ORDER BY metadata_date DESC
LIMIT 100;