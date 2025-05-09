WITH candidate AS (
  SELECT
    q.id,
    q.title,
    q.view_count,
    t AS tag,
    q.body
  FROM
    `bigquery-public-data.stackoverflow.posts_questions` AS q,
    UNNEST(SPLIT(q.tags, '|')) AS t
  WHERE
    t IN ('android-layout','android-activity','android-intent',
          'android-edittext','android-fragments','android-recyclerview',
          'listview','android-actionbar','google-maps','android-asynctask')
    -- must contain the word "how" in title or body
    AND (
      REGEXP_CONTAINS(LOWER(COALESCE(q.title, '')), r'\bhow\b') OR
      REGEXP_CONTAINS(LOWER(COALESCE(q.body , '')), r'\bhow\b')
    )
    -- must NOT contain any troubleshooting terms
    AND NOT REGEXP_CONTAINS(
      LOWER(COALESCE(q.title, '') || ' ' || COALESCE(q.body, '')),
      r'\b(fail|problem|error|wrong|fix|bug|issue|solve|trouble)\b'
    )
),
ranked AS (
  SELECT
    id,
    title,
    view_count,
    tag,
    ROW_NUMBER() OVER (PARTITION BY tag ORDER BY view_count DESC) AS rn,
    COUNT(*)   OVER (PARTITION BY tag)                           AS total_per_tag
  FROM candidate
)
SELECT
  tag,
  id,
  title,
  view_count
FROM
  ranked
WHERE
  total_per_tag >= 50   -- keep tags with at least 50 qualified questions
  AND rn <= 50          -- top-50 most-viewed questions per such tag
ORDER BY
  tag,
  view_count DESC;