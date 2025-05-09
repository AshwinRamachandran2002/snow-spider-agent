/* Top 50 most–viewed questions per Android‑related tag that
   (1) contain the word “how” in title or body,
   (2) do NOT contain any common troubleshooting terms,
   (3) come from tags that have ≥ 50 such questions           */

WITH
-- 1. Questions that meet the textual requirements
eligible_questions AS (
  SELECT
    q.id,
    q.title,
    q.body,
    q.view_count,
    LOWER(t) AS tag
  FROM `bigquery-public-data.stackoverflow.posts_questions` AS q
  -- explode pipe‑delimited tag string into individual tags
  CROSS JOIN UNNEST(SPLIT(LOWER(q.tags), '|')) AS t
  WHERE LOWER(t) IN (
        'android-layout','android-activity','android-intent','android-edittext',
        'android-fragments','android-recyclerview','listview',
        'android-actionbar','google-maps','android-asynctask')
    -- must contain the word “how”
    AND (REGEXP_CONTAINS(LOWER(q.title), r'\bhow\b')
         OR REGEXP_CONTAINS(LOWER(q.body),  r'\bhow\b'))
    -- must NOT contain any troubleshooting terms
    AND NOT REGEXP_CONTAINS(LOWER(q.title), r'\b(fail|problem|error|wrong|fix|bug|issue|solve|trouble)\b')
    AND NOT REGEXP_CONTAINS(LOWER(q.body),  r'\b(fail|problem|error|wrong|fix|bug|issue|solve|trouble)\b')
),

-- 2. Keep only tags that have at least 50 qualifying questions
qualified_tags AS (
  SELECT tag
  FROM eligible_questions
  GROUP BY tag
  HAVING COUNT(*) >= 50
),

-- 3. Rank questions by view count within each qualifying tag
ranked AS (
  SELECT
    eq.tag,
    eq.id,
    eq.title,
    eq.view_count,
    ROW_NUMBER() OVER (PARTITION BY eq.tag
                       ORDER BY eq.view_count DESC, eq.id) AS rn
  FROM eligible_questions AS eq
  JOIN qualified_tags USING (tag)
)

-- 4. Return the top 50 per tag
SELECT
  tag,
  id          AS question_id,
  title,
  view_count
FROM ranked
WHERE rn <= 50
ORDER BY tag, view_count DESC, question_id;