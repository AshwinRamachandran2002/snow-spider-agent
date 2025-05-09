/* Top 10 Stack Overflow tags most frequently referenced
   in Hacker News comments (from 2014‑01‑01 onward)      */

WITH hn_comments AS (               -- Hacker News comments since 2014‑01‑01
  SELECT
    id,
    text,
    time
  FROM `bigquery-public-data.hacker_news.full`
  WHERE type = 'comment'
    AND time >= 1388534400          -- 2014‑01‑01 00:00:00 UTC
),

hn_refs AS (                        -- every Stack Overflow question ID mentioned
  SELECT
    CAST(qid AS INT64) AS question_id,
    1                   AS mention
  FROM hn_comments,
  UNNEST(
    REGEXP_EXTRACT_ALL(
      LOWER(COALESCE(text, '')),
      r'stackoverflow\.com\/questions\/(\d+)'   -- “…/questions/<id>”
    )
  ) AS qid
),

question_mentions AS (              -- count mentions per question
  SELECT
    question_id,
    COUNT(*) AS mentions
  FROM hn_refs
  GROUP BY question_id
),

question_tags AS (                  -- attach Stack Overflow tag strings
  SELECT
    qm.mentions,
    pq.tags                                -- pipe‑delimited tag list
  FROM question_mentions qm
  JOIN `bigquery-public-data.stackoverflow.posts_questions` pq
    ON pq.id = qm.question_id
  WHERE pq.tags IS NOT NULL
),

tag_totals AS (                     -- split tags and sum the mentions
  SELECT
    tag,
    SUM(mentions) AS total_mentions
  FROM question_tags,
  UNNEST(SPLIT(tags, '|')) AS tag
  GROUP BY tag
)

SELECT
  tag,
  total_mentions
FROM tag_totals
ORDER BY total_mentions DESC, tag
LIMIT 10;