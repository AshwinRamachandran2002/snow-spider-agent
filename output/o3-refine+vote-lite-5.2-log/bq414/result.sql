-- Object id, title, and metadata date (YYYY-MM-DD) for
-- Library‑department objects whose title contains “book”
-- and that have at least one crop hint with confidence > 0.5
SELECT
  o.object_id,
  o.title,
  FORMAT_TIMESTAMP('%F', o.metadata_date) AS metadata_date
FROM `bigquery-public-data.the_met.objects`            AS o
JOIN (
  SELECT DISTINCT object_id
  FROM `bigquery-public-data.the_met.vision_api_data`,
       UNNEST(cropHintsAnnotation.cropHints) AS ch
  WHERE ch.confidence > 0.5
) AS v
ON o.object_id = v.object_id
WHERE o.department = 'The Libraries'
  AND o.title IS NOT NULL
  AND LOWER(o.title) LIKE '%book%';