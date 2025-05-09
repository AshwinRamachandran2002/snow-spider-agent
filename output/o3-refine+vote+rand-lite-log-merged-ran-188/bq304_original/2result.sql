-- Top‑50 most‑viewed questions (per tag) that
--   • belong to one of the requested Android‑related tags  
--   • contain the word “how” (case‑insensitive) in title or body  
--   • DO NOT contain any troubleshooting terms in title or body  
-- Only tags with ≥ 50 qualifying questions are kept.

WITH candidate_questions AS (
  SELECT
    q.id,
    q.title,
    q.body,
    COALESCE(q.view_count, 0) AS view_count,
    tag
  FROM `bigquery-public-data.stackoverflow.posts_questions` AS q
  -- explode the pipe‑delimited tag list
  CROSS JOIN UNNEST(SPLIT(q.tags, '|')) AS tag
  WHERE tag IN (
      'android-layout', 'android-activity', 'android-intent',
      'android-edittext', 'android-fragments', 'android-recyclerview',
      'listview', 'android-actionbar', 'google-maps', 'android-asynctask'
    )
    -- must contain the word “how”
    AND (
        REGEXP_CONTAINS(LOWER(q.title), r'\bhow\b')
        OR REGEXP_CONTAINS(LOWER(q.body),  r'\bhow\b')
    )
    -- must NOT contain any troubleshooting terms
    AND NOT (
        REGEXP_CONTAINS(LOWER(q.title), r'\b(fail|problem|error|wrong|fix|bug|issue|solve|trouble)\b')
        OR REGEXP_CONTAINS(LOWER(q.body),  r'\b(fail|problem|error|wrong|fix|bug|issue|solve|trouble)\b')
    )
),

tags_with_enough AS (
  SELECT tag
  FROM candidate_questions
  GROUP BY tag
  HAVING COUNT(*) >= 50          -- keep only tags with ≥ 50 qualifying questions
),

ranked AS (
  SELECT
    c.tag,
    c.id,
    c.title,
    c.view_count,
    ROW_NUMBER() OVER (
        PARTITION BY c.tag
        ORDER BY c.view_count DESC, c.id DESC   -- tie‑breaker on id
    ) AS rn
  FROM candidate_questions AS c
  JOIN tags_with_enough USING (tag)
)

SELECT
  tag,
  id,
  title,
  view_count
FROM ranked
WHERE rn <= 50                  -- top‑50 per remaining tag
ORDER BY tag, rn;