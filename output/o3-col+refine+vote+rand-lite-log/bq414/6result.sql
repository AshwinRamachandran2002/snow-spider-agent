-- Retrieve object id, title, and formatted metadata_date for
-- "The Libraries" objects whose titles contain "book" and whose
-- maximum crop confidence is greater than 0.5.
SELECT
  o.`object_id`,
  o.`title`,
  FORMAT_DATE('%F', DATE(o.`metadata_date`)) AS `metadata_date`
FROM `bigquery-public-data.the_met.objects` AS o
JOIN (
  -- Calculate maximum crop confidence per object
  SELECT
    v.`object_id`,
    MAX(ch.`confidence`) AS max_crop_confidence
  FROM `bigquery-public-data.the_met.vision_api_data` AS v
  CROSS JOIN UNNEST(v.`cropHintsAnnotation`.cropHints) AS ch
  GROUP BY v.`object_id`
) AS mc
ON o.`object_id` = mc.`object_id`
WHERE o.`department` = 'The Libraries'
  AND mc.max_crop_confidence > 0.5
  AND o.`title` IS NOT NULL
  AND LOWER(o.`title`) LIKE '%book%';