SELECT DISTINCT
  o.object_id,
  o.title,
  FORMAT_DATE('%F', DATE(o.metadata_date)) AS metadata_date
FROM `bigquery-public-data.the_met.objects`         AS o
JOIN `bigquery-public-data.the_met.vision_api_data` AS v
ON  o.object_id = v.object_id
JOIN UNNEST(v.cropHintsAnnotation.cropHints) AS hints
WHERE o.department = 'The Libraries'
  AND hints.confidence > 0.5
  AND LOWER(o.title) LIKE '%book%';