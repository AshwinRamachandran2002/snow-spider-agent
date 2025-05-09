SELECT
  period,
  label,
  artworks
FROM (
  SELECT
    o.period,
    l.description AS label,
    COUNT(DISTINCT o.object_id) AS artworks,
    ROW_NUMBER() OVER (
      PARTITION BY o.period
      ORDER BY COUNT(DISTINCT o.object_id) DESC
    ) AS rn
  FROM
    `bigquery-public-data.the_met.objects` AS o
  JOIN
    `bigquery-public-data.the_met.vision_api_data` AS v
  ON
    o.object_id = v.object_id
  CROSS JOIN
    UNNEST(v.labelAnnotations) AS l
  WHERE
    o.period IS NOT NULL
  GROUP BY
    o.period,
    label
  HAVING
    COUNT(DISTINCT o.object_id) >= 500
)
WHERE
  rn <= 3
ORDER BY
  period,
  artworks DESC,
  label;