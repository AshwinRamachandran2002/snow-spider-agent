WITH target_tags AS (
  SELECT 'android-layout'       AS tag UNION ALL
  SELECT 'android-activity'     UNION ALL
  SELECT 'android-intent'       UNION ALL
  SELECT 'android-edittext'     UNION ALL
  SELECT 'android-fragments'    UNION ALL
  SELECT 'android-recyclerview' UNION ALL
  SELECT 'listview'             UNION ALL
  SELECT 'android-actionbar'    UNION ALL
  SELECT 'google-maps'          UNION ALL
  SELECT 'android-asynctask'
),
candidate_questions AS (
  SELECT
    q.id,
    q.title,
    q.body,
    q.view_count,
    q.creation_date,
    t.tag
  FROM `bigquery-public-data.stackoverflow.posts_questions` AS q
  CROSS JOIN UNNEST(SPLIT(q.tags, '|')) AS tag_str
  JOIN target_tags AS t
    ON tag_str = t.tag
  WHERE
    (REGEXP_CONTAINS(LOWER(COALESCE(q.title, '')), r'\bhow\b')
     OR REGEXP_CONTAINS(LOWER(q.body), r'\bhow\b'))
    AND NOT REGEXP_CONTAINS(LOWER(COALESCE(q.title, '')),
                             r'\b(fail|problem|error|wrong|fix|bug|issue|solve|trouble)\b')
    AND NOT REGEXP_CONTAINS(LOWER(q.body),
                             r'\b(fail|problem|error|wrong|fix|bug|issue|solve|trouble)\b')
),
valid_tags AS (
  SELECT tag
  FROM candidate_questions
  GROUP BY tag
  HAVING COUNT(*) >= 50
)
SELECT
  tag,
  id,
  title,
  view_count,
  creation_date
FROM (
  SELECT
    cq.*,
    ROW_NUMBER() OVER (PARTITION BY tag ORDER BY view_count DESC, id) AS rn
  FROM candidate_questions AS cq
  JOIN valid_tags USING (tag)
)
WHERE rn <= 50
ORDER BY tag, view_count DESC, id;