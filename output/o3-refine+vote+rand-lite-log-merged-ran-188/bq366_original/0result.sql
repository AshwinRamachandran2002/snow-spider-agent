WITH labels_per_object AS (
  -- every (object_id , label) pair found by Vision API
  SELECT
    v.object_id,
    LOWER(l.description) AS label
  FROM
    `bigquery-public-data.the_met.vision_api_data` AS v,
    UNNEST(v.labelAnnotations) AS l
  WHERE
    l.description IS NOT NULL
),
popular_labels AS (
  -- keep only labels that appear with ≥ 500 different artworks
  SELECT
    label
  FROM
    labels_per_object
  GROUP BY
    label
  HAVING
    COUNT(DISTINCT object_id) >= 500
),
period_label_counts AS (
  -- for those popular labels, count how many artworks of each historical period carry the label
  SELECT
    o.period,
    lp.label,
    COUNT(DISTINCT lp.object_id) AS cnt
  FROM
    labels_per_object AS lp
  JOIN
    popular_labels  AS pl  ON lp.label = pl.label
  JOIN
    `bigquery-public-data.the_met.objects` AS o
      ON lp.object_id = o.object_id
  WHERE
    o.period IS NOT NULL
  GROUP BY
    o.period,
    lp.label
),
ranked AS (
  -- rank labels within each period by their counts
  SELECT
    plc.*,
    ROW_NUMBER() OVER (PARTITION BY period ORDER BY cnt DESC, label) AS rn
  FROM
    period_label_counts AS plc
)
-- return the top three labels for each period
SELECT
  period,
  label,
  cnt
FROM
  ranked
WHERE
  rn <= 3
ORDER BY
  period,
  rn;