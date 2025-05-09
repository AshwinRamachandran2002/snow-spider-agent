-- Top 50 most‑viewed questions (per tag) that
--   • belong to one of the requested Android–related tags
--   • contain the word “how” in title or body
--   • do NOT contain any common troubleshooting words
-- Only tags with at least 50 matching questions are returned.

WITH
-- list of tags we care about
tags_of_interest AS (
  SELECT 'android-layout'     AS tag UNION ALL
  SELECT 'android-activity'   UNION ALL
  SELECT 'android-intent'     UNION ALL
  SELECT 'android-edittext'   UNION ALL
  SELECT 'android-fragments'  UNION ALL
  SELECT 'android-recyclerview' UNION ALL
  SELECT 'listview'           UNION ALL
  SELECT 'android-actionbar'  UNION ALL
  SELECT 'google-maps'        UNION ALL
  SELECT 'android-asynctask'
),

-- all questions that (1) have one of those tags,
-- (2) include 'how', and (3) exclude the troubleshooting words
filtered AS (
  SELECT
    q.id,
    q.title,
    q.body,
    q.view_count,
    t.tag
  FROM `bigquery-public-data.stackoverflow.posts_questions` AS q
  -- break the pipe‑separated tag string into individual tags
  CROSS JOIN UNNEST(SPLIT(q.tags, '|')) AS tag
  JOIN tags_of_interest  AS t  ON tag = t.tag
  WHERE
    -- must contain the word "how" in title or body
    ( REGEXP_CONTAINS(LOWER(q.title), r'\bhow\b')
      OR REGEXP_CONTAINS(LOWER(q.body),  r'\bhow\b') )
    -- must NOT contain any troubleshooting terms
    AND NOT (
       REGEXP_CONTAINS(LOWER(q.title), r'\b(fail|problem|error|wrong|fix|bug|issue|solve|trouble)\b')
    OR REGEXP_CONTAINS(LOWER(q.body),  r'\b(fail|problem|error|wrong|fix|bug|issue|solve|trouble)\b')
    )
),

-- keep only those tags that have at least 50 qualifying questions
eligible_tags AS (
  SELECT tag
  FROM filtered
  GROUP BY tag
  HAVING COUNT(*) >= 50
),

-- rank questions inside each eligible tag by view count (highest first)
ranked AS (
  SELECT
    f.*,
    ROW_NUMBER() OVER (PARTITION BY f.tag
                       ORDER BY f.view_count DESC, f.id) AS rn
  FROM filtered AS f
  JOIN eligible_tags AS e
  ON f.tag = e.tag
)

-- final result: top 50 per eligible tag
SELECT
  tag,
  id         AS question_id,
  title,
  view_count
FROM ranked
WHERE rn <= 50
ORDER BY tag, rn;