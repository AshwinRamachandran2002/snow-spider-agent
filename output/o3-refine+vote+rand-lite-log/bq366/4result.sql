WITH valid_labels AS (
  -- keep only the labels that appear on at least 500 different artworks
  SELECT
    la.description AS label,
    COUNT(DISTINCT object_id) AS artwork_cnt
  FROM `bigquery-public-data.the_met.vision_api_data`,
       UNNEST(labelAnnotations) AS la
  GROUP BY la.description
  HAVING artwork_cnt >= 500
),
period_label_counts AS (
  -- count, for every (period , label) pair, how many artworks carry that label
  SELECT
    o.period,
    la.description AS label,
    COUNT(DISTINCT o.object_id) AS cnt
  FROM `bigquery-public-data.the_met.objects` AS o
  JOIN `bigquery-public-data.the_met.vision_api_data` AS v
    ON o.object_id = v.object_id
  JOIN UNNEST(v.labelAnnotations) AS la
  JOIN valid_labels vl                -- restrict to the “frequent” labels
    ON la.description = vl.label
  WHERE o.period IS NOT NULL
    AND TRIM(o.period) <> ''          -- ignore blank periods
  GROUP BY o.period, la.description
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
  cnt AS count
FROM ranked
WHERE rn <= 3                       -- top‑3 per period
ORDER BY period, rn;