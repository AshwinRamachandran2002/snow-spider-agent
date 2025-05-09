WITH base AS (
  -- questions that match all textual conditions and belong to a target tag
  SELECT
    q.id,
    q.title,
    q.view_count,
    tag
  FROM `bigquery-public-data.stackoverflow.posts_questions` AS q
  CROSS JOIN UNNEST(SPLIT(q.tags, '|')) AS tag
  WHERE tag IN ('android-layout','android-activity','android-intent',
                'android-edittext','android-fragments','android-recyclerview',
                'listview','android-actionbar','google-maps','android-asynctask')
    -- must contain the word "how"
    AND REGEXP_CONTAINS(
          LOWER(CONCAT(IFNULL(q.title,''),' ',IFNULL(q.body,''))),
          r'\bhow\b')
    -- must NOT contain any troubleshooting terms
    AND NOT REGEXP_CONTAINS(
          LOWER(CONCAT(IFNULL(q.title,''),' ',IFNULL(q.body,''))),
          r'(fail|problem|error|wrong|fix|bug|issue|solve|trouble)')
),
qualified_tags AS (
  -- keep only tags that have at least 50 qualifying questions
  SELECT tag
  FROM base
  GROUP BY tag
  HAVING COUNT(*) >= 50
),
ranked AS (
  -- rank questions inside each tag by view count
  SELECT
    b.id,
    b.title,
    b.view_count,
    b.tag,
    ROW_NUMBER() OVER (PARTITION BY b.tag ORDER BY b.view_count DESC) AS rn
  FROM base AS b
  JOIN qualified_tags USING (tag)
)
-- top‑50 most viewed questions per qualified tag
SELECT
  id,
  title,
  view_count,
  tag
FROM ranked
WHERE rn <= 50
ORDER BY tag, view_count DESC;