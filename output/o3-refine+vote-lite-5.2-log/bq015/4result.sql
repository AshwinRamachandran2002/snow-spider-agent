/* Top‑10 Stack Overflow tags that appear most often in Hacker News comment links (2014‑present) */
WITH hn_refs AS (        -- 1. every SO‑question id mentioned in HN comments
  SELECT
    CAST(qid AS INT64) AS question_id
  FROM
    `bigquery-public-data.hacker_news.full` AS hn,
    UNNEST(
      REGEXP_EXTRACT_ALL(
        LOWER(hn.text),                                   -- e.g. …stackoverflow.com/questions/123456…
        r'https?://(?:www\.)?stackoverflow\.com/(?:questions|q)/([0-9]+)'
      )
    ) AS qid
  WHERE
    hn.type = 'comment'
    AND hn.text IS NOT NULL
    AND hn.time >= UNIX_SECONDS(TIMESTAMP '2014-01-01')
),
question_counts AS (      -- 2. how many times is each question linked?
  SELECT
    question_id,
    COUNT(*) AS mention_count
  FROM hn_refs
  GROUP BY question_id
),
question_tags AS (        -- 3. bring in SO tag strings
  SELECT
    qc.question_id,
    qc.mention_count,
    pq.tags                                 -- tag string like 'python|django|pandas'
  FROM question_counts AS qc
  JOIN `bigquery-public-data.stackoverflow.posts_questions` AS pq
    ON pq.id = qc.question_id
  WHERE pq.tags IS NOT NULL
),
tag_counts AS (           -- 4. explode tags, aggregate by tag
  SELECT
    tag,
    SUM(mention_count) AS total_mentions
  FROM question_tags,
    UNNEST(SPLIT(tags, '|')) AS tag
  GROUP BY tag
)
-- 5. top 10 tags
SELECT
  tag,
  total_mentions
FROM tag_counts
ORDER BY total_mentions DESC, tag
LIMIT 10;