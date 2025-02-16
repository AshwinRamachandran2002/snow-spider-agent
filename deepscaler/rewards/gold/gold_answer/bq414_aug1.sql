-- Task: Retrieve the object id, title, formatted metadata date (as a string in 'YYYY-MM-DD' format), and cropConfidence for objects in the "The Libraries" department where the object's title contains the word "book". Limit the results to 100 entries.

SELECT DISTINCT o.`object_id`,
                o.`title`,
                FORMAT_DATE('%Y-%m-%d', DATE(o.`metadata_date`)) AS metadata_date,
                cropHint.confidence AS cropConfidence
FROM `bigquery-public-data.the_met.objects` AS o
INNER JOIN `bigquery-public-data.the_met.vision_api_data` AS v
  ON o.`object_id` = v.`object_id`
CROSS JOIN UNNEST(v.`cropHintsAnnotation`.cropHints) AS cropHint
WHERE o.`department` = 'The Libraries'
  AND o.`title` LIKE '%book%'
ORDER BY metadata_date DESC
LIMIT 100;