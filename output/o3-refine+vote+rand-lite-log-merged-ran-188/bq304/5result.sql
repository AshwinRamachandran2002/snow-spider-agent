-- Top-50 most-viewed “how” questions per eligible Android-related tag
WITH target_tags AS (
  SELECT tag
  FROM UNNEST([
    'android-layout',
    'android-activity',
    'android-intent',
    'android-edittext',
    'android-fragments',
    'android-recyclerview',
    'listview',
    'android-actionbar',
    'google-maps',
    'android-asynctask'
  ]) AS tag
),
-- questions that satisfy all textual requirements for any of the 10 tags
qualified_questions AS (
  SELECT
    q.id,
    q.title,
    q.view_count,
    t.tag
  FROM `bigquery-public-data.stackoverflow.posts_questions` AS q
  CROSS JOIN target_tags AS t
  WHERE
    -- tag match (tags are pipe-delimited)
    REGEXP_CONTAINS(
      LOWER(COALESCE(q.tags, '')),
      CONCAT(r'(^|[|])', t.tag, r'([|]|$)')
    )
    -- must contain the word “how” in title or body
    AND (
      REGEXP_CONTAINS(LOWER(COALESCE(q.title, '')), r'\bhow\b') OR
      REGEXP_CONTAINS(LOWER(COALESCE(q.body , '')), r'\bhow\b')
    )
    -- must NOT contain troubleshooting words
    AND NOT REGEXP_CONTAINS(
      LOWER(CONCAT(COALESCE(q.title, ''), ' ', COALESCE(q.body, ''))),
      r'\b(fail|problem|error|wrong|fix|bug|issue|solve|trouble)\b'
    )
),
-- keep only tags that have at least 50 qualifying questions
eligible_tags AS (
  SELECT tag
  FROM qualified_questions
  GROUP BY tag
  HAVING COUNT(*) >= 50
),
-- rank questions by view count within each eligible tag
ranked AS (
  SELECT
    q.id,
    q.title,
    q.view_count,
    q.tag,
    ROW_NUMBER() OVER (PARTITION BY q.tag ORDER BY q.view_count DESC) AS rn
  FROM qualified_questions AS q
  JOIN eligible_tags USING (tag)
)
-- final result: top-50 by view count for every eligible tag
SELECT
  id,
  title,
  view_count,
  tag
FROM ranked
WHERE rn <= 50
ORDER BY tag, view_count DESC;