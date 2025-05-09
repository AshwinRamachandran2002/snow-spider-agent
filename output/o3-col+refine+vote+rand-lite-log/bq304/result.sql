-- Top-viewed “how” questions (no troubleshooting words) for selected Android tags
WITH target_tags AS (
  SELECT tag
  FROM UNNEST([
    'android-layout','android-activity','android-intent','android-edittext',
    'android-fragments','android-recyclerview','listview',
    'android-actionbar','google-maps','android-asynctask'
  ]) AS tag
),

filtered AS (
  SELECT
    q.id,
    q.title,
    q.view_count,
    t.tag
  FROM `bigquery-public-data.stackoverflow.posts_questions` AS q
  JOIN target_tags                     AS t
    ON REGEXP_CONTAINS(q.tags, CONCAT('(^|[|])', t.tag, '([|]|$)'))
  WHERE
    -- must contain the word “how” (title or body)
    (REGEXP_CONTAINS(LOWER(COALESCE(q.title,'')), r'\bhow\b')
     OR REGEXP_CONTAINS(LOWER(q.body),             r'\bhow\b'))
    -- must NOT contain any troubleshooting terms (title or body)
    AND NOT (
      REGEXP_CONTAINS(LOWER(COALESCE(q.title,'')),
                      r'\b(fail|problem|error|wrong|fix|bug|issue|solve|trouble)\b')
      OR REGEXP_CONTAINS(LOWER(q.body),
                         r'\b(fail|problem|error|wrong|fix|bug|issue|solve|trouble)\b')
    )
),

qualified_tags AS (
  SELECT tag
  FROM   filtered
  GROUP  BY tag
  HAVING COUNT(*) >= 50               -- keep only tags with ≥ 50 qualifying questions
),

ranked AS (
  SELECT
    f.tag,
    f.id,
    f.title,
    f.view_count,
    ROW_NUMBER() OVER (PARTITION BY f.tag ORDER BY f.view_count DESC) AS rn
  FROM filtered AS f
  JOIN qualified_tags USING (tag)
)

SELECT
  tag,
  id,
  title,
  view_count
FROM ranked
WHERE rn <= 50                        -- top 50 per qualified tag
ORDER BY tag, view_count DESC;