/* Top‑10 Stack Overflow tags found in questions that were referenced
   inside Hacker News comments dated 2014‑01‑01 or later */
WITH hn_refs AS (
  -- 1. Locate every Stack Overflow question URL in Hacker News comments
  SELECT
    id AS hn_comment_id,
    REGEXP_EXTRACT_ALL(
      LOWER(COALESCE(text, '')),
      r'https?://stackoverflow\.com/(?:questions|q)/(\d+)'   -- capture question id(s)
    ) AS question_ids
  FROM `bigquery-public-data.hacker_news.full`
  WHERE type = 'comment'
    AND `timestamp` >= TIMESTAMP('2014-01-01')               -- only comments from 2014+
),
mentions AS (
  -- 2. One row per individual mention of a Stack Overflow question
  SELECT
    CAST(id_str AS INT64) AS question_id
  FROM hn_refs, UNNEST(question_ids) AS id_str
),
q_with_tags AS (
  -- 3. Bring in the tag list for each mentioned question
  SELECT
    m.question_id,
    pq.tags
  FROM mentions AS m
  JOIN `bigquery-public-data.stackoverflow.posts_questions` AS pq
  ON m.question_id = pq.id
  WHERE pq.tags IS NOT NULL
)
-- 4. Split the tag strings, count mentions, and list the top 10
SELECT
  tag,
  COUNT(*) AS mention_count
FROM q_with_tags, UNNEST(SPLIT(tags, '|')) AS tag
GROUP BY tag
ORDER BY mention_count DESC, tag
LIMIT 10;