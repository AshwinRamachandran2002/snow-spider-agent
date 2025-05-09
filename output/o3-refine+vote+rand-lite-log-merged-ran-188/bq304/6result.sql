WITH prefiltered AS (
  SELECT
    id,
    title,
    body,
    view_count,
    SPLIT(tags, '|') AS tag_arr
  FROM `bigquery-public-data.stackoverflow.posts_questions`
  WHERE
    -- must contain the word “how”
    (REGEXP_CONTAINS(LOWER(title), r'\bhow\b')
     OR REGEXP_CONTAINS(LOWER(body),  r'\bhow\b'))
    -- must NOT contain any troubleshooting words
    AND NOT REGEXP_CONTAINS(LOWER(title), r'fail|problem|error|wrong|fix|bug|issue|solve|trouble')
    AND NOT REGEXP_CONTAINS(LOWER(body),  r'fail|problem|error|wrong|fix|bug|issue|solve|trouble')
),
exploded AS (
  SELECT
    id,
    title,
    view_count,
    tag
  FROM prefiltered,
  UNNEST(tag_arr) AS tag
  WHERE tag IN (
        'android-layout', 'android-activity', 'android-intent',
        'android-edittext', 'android-fragments', 'android-recyclerview',
        'listview', 'android-actionbar', 'google-maps', 'android-asynctask'
  )
),
qualified_tags AS (          -- keep only tags having ≥ 50 qualified questions
  SELECT tag
  FROM exploded
  GROUP BY tag
  HAVING COUNT(*) >= 50
),
ranked AS (
  SELECT
    id,
    title,
    view_count,
    tag,
    ROW_NUMBER() OVER (PARTITION BY tag ORDER BY view_count DESC) AS rn
  FROM exploded
  WHERE tag IN (SELECT tag FROM qualified_tags)
)
SELECT
  id,
  title,
  view_count,
  tag
FROM ranked
WHERE rn <= 50
ORDER BY tag, view_count DESC;