WITH comment_question_mentions AS (
  -- Extract every Stack Overflow question id mentioned in Hacker News comments (from 2014‑01‑01 on)
  SELECT
    CAST(id_str AS INT64) AS question_id
  FROM `bigquery-public-data.hacker_news.full` AS hn
  CROSS JOIN UNNEST(
    REGEXP_EXTRACT_ALL(
      IFNULL(hn.text, ''),
      r'https?://(?:www\.)?stackoverflow\.com/questions/([0-9]+)'
    )
  ) AS id_str
  WHERE hn.type = 'comment'
    AND hn.time >= 1388534400              -- 2014‑01‑01 UTC
),

question_mention_counts AS (
  -- Count how many times each distinct question was linked
  SELECT
    question_id,
    COUNT(*) AS mention_cnt
  FROM comment_question_mentions
  GROUP BY question_id
),

so_questions_with_counts AS (
  -- Attach Stack Overflow tag strings to each mentioned question
  SELECT
    q.id   AS question_id,
    q.tags AS tag_string,                  -- pipe‑delimited
    qc.mention_cnt
  FROM `bigquery-public-data.stackoverflow.posts_questions` AS q
  JOIN question_mention_counts AS qc
    ON q.id = qc.question_id
),

tag_mentions AS (
  -- Split tag strings and sum mentions per individual tag
  SELECT
    tag,
    SUM(mention_cnt) AS total_mentions
  FROM so_questions_with_counts,
       UNNEST(SPLIT(tag_string, '|')) AS tag
  GROUP BY tag
)

SELECT
  tag,
  total_mentions
FROM tag_mentions
ORDER BY total_mentions DESC, tag
LIMIT 10;