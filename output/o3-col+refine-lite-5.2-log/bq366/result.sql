-- Top three most frequent Vision‑API labels per historical period
-- (labels must appear on ≥500 artworks within that period)
WITH period_label_counts AS (
  SELECT
    obj.period,
    lbl.description AS label,
    COUNT(DISTINCT obj.object_id) AS cnt
  FROM
    `bigquery-public-data.the_met.objects`        AS obj
  JOIN
    `bigquery-public-data.the_met.vision_api_data` AS vid
  ON  obj.object_id = vid.object_id
  CROSS JOIN
    UNNEST(vid.labelAnnotations) AS lbl
  WHERE
    obj.period IS NOT NULL
  GROUP BY
    obj.period, label
  HAVING
    cnt >= 500          -- keep only labels linked to ≥500 artworks in that period
),
ranked AS (
  SELECT
    period,
    label,
    cnt,
    ROW_NUMBER() OVER (PARTITION BY period
                       ORDER BY cnt DESC, label) AS rn
  FROM period_label_counts
)
SELECT
  period,
  label,
  cnt
FROM ranked
WHERE rn <= 3               -- top 3 per period
ORDER BY
  period,
  cnt DESC;