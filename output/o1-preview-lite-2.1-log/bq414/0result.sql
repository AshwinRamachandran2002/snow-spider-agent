SELECT
  o.`object_id`,
  o.`title`,
  FORMAT_DATE('%Y-%m-%d', DATE(o.`metadata_date`)) AS `metadata_date`
FROM `bigquery-public-data.the_met.objects` AS o
JOIN `bigquery-public-data.the_met.vision_api_data` AS v
  ON o.`object_id` = v.`object_id`
CROSS JOIN UNNEST(v.`cropHintsAnnotation`.`cropHints`) AS c
WHERE o.`department` = 'The Libraries'
  AND LOWER(o.`title`) LIKE '%book%'
  AND c.`confidence` > 0.5;