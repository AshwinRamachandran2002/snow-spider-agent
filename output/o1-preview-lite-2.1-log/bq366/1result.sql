WITH labels_over_50 AS (
  SELECT
    la.description AS label
  FROM
    `bigquery-public-data.the_met.vision_api_data` AS v
  CROSS JOIN
    UNNEST(v.labelAnnotations) AS la
  GROUP BY
    la.description
  HAVING
    COUNT(DISTINCT v.object_id) >= 50
),
period_label_counts AS (
  SELECT
    o.period,
    la.description AS label,
    COUNT(DISTINCT o.object_id) AS artwork_count
  FROM
    `bigquery-public-data.the_met.objects` AS o
  JOIN
    `bigquery-public-data.the_met.vision_api_data` AS v
    ON o.object_id = v.object_id
  CROSS JOIN
    UNNEST(v.labelAnnotations) AS la
  WHERE
    o.period IS NOT NULL
    AND o.period != ''
    AND la.description IN (SELECT label FROM labels_over_50)
  GROUP BY
    o.period,
    la.description
),
ranked_labels AS (
  SELECT
    period,
    label,
    artwork_count,
    ROW_NUMBER() OVER (PARTITION BY period ORDER BY artwork_count DESC) AS rn
  FROM
    period_label_counts
)
SELECT
  period,
  label,
  artwork_count AS count
FROM
  ranked_labels
WHERE
  rn <= 3
ORDER BY
  period,
  count DESC