-- Top 10 Stack Overflow tags most frequently referenced in Hacker News comments (from 2014 onward)
WITH hn_comments AS (
  SELECT
    id,
    LOWER(text) AS text
  FROM `bigquery-public-data.hacker_news.full`
  WHERE
    type = 'comment'
    AND time >= UNIX_SECONDS(TIMESTAMP '2014-01-01')
    AND text IS NOT NULL
    AND LOWER(text) LIKE '%stackoverflow.com/%'          -- pre‑filter to rows that mention SO
),
stack_refs AS (
  SELECT
    id AS hn_comment_id,
    REGEXP_EXTRACT_ALL(
      text,
      r'stackoverflow\.com/(?:questions|q)/([0-9]+)'
    ) AS qids                                            -- all referenced SO question IDs
  FROM hn_comments
),
question_mentions AS (
  SELECT
    CAST(qid AS INT64) AS question_id,
    COUNT(*)          AS mention_count                   -- times each question was cited
  FROM stack_refs, UNNEST(qids) AS qid
  GROUP BY question_id
),
question_tags AS (
  SELECT
    qm.question_id,
    qm.mention_count,
    pq.tags                                              -- pipe‑delimited tag string
  FROM question_mentions qm
  JOIN `bigquery-public-data.stackoverflow.posts_questions` pq
    ON pq.id = qm.question_id
  WHERE pq.tags IS NOT NULL
),
tag_counts AS (
  SELECT
    tag,
    SUM(mention_count) AS total_mentions
  FROM question_tags,
  UNNEST(SPLIT(tags, '|')) AS tag                        -- split the tag list
  GROUP BY tag
)
SELECT
  tag,
  total_mentions
FROM tag_counts
ORDER BY total_mentions DESC, tag
LIMIT 10;