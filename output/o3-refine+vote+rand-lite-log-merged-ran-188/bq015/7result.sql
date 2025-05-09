/*  Top‑10 Stack Overflow tags that appear most often in
    SO‑question links inside Hacker News comments (2014‑present) */

WITH hn_comments AS (            -- all HN comments from 2014‑01‑01 onward
  SELECT
    id AS comment_id,
    COALESCE(text, '') AS text
  FROM `bigquery-public-data.hacker_news.full`
  WHERE type = 'comment'
    AND time >= 1388534400            -- 2014‑01‑01 00:00:00 UTC
),

so_mentions AS (                 -- every SO‑question id mentioned in those comments
  SELECT
    comment_id,
    CAST(qid AS INT64) AS question_id
  FROM hn_comments,
  UNNEST(
    REGEXP_EXTRACT_ALL(
      LOWER(text),
      r'https?://stackoverflow\.com/questions/([0-9]+)'
    )
  ) AS qid
),

question_mention_counts AS (     -- count mentions per SO question
  SELECT
    question_id,
    COUNT(*) AS mention_count
  FROM so_mentions
  GROUP BY question_id
),

tag_mentions AS (                -- explode tags and attribute the counts
  SELECT
    tag,
    qmc.mention_count
  FROM question_mention_counts AS qmc
  JOIN `bigquery-public-data.stackoverflow.posts_questions` AS pq
    ON pq.id = qmc.question_id
  CROSS JOIN UNNEST(SPLIT(pq.tags, '|')) AS tag
  WHERE tag <> ''
)

SELECT                            -- aggregate per tag and return the top‑10
  tag,
  SUM(mention_count) AS total_mentions
FROM tag_mentions
GROUP BY tag
ORDER BY total_mentions DESC, tag
LIMIT 10;