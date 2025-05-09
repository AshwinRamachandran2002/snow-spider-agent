/*  Top‑10 Stack Overflow tags referenced from Hacker News comments (on/after 2014) */

WITH comment_refs AS (          -- how many times each SO question is mentioned
  SELECT
    CAST(
      REGEXP_EXTRACT(LOWER(text),
                     r'stackoverflow\.com/questions/([0-9]+)') AS INT64
    )        AS question_id,
    COUNT(*) AS mentions
  FROM `bigquery-public-data.hacker_news.full`
  WHERE type = 'comment'
    AND time >= 1388534400                              -- 2014‑01‑01
    AND REGEXP_CONTAINS(LOWER(text),
                        r'stackoverflow\.com/questions/[0-9]+')
  GROUP BY question_id
  HAVING question_id IS NOT NULL
),

question_tags AS (              -- pipe‑delimited tag strings → array
  SELECT
    Id AS question_id,
    SPLIT(
      REGEXP_REPLACE(                       -- turn "<a><b>" → "a|b"
        REGEXP_REPLACE(Tags, r'^<|>$', ''),
        r'><', '|'
      ),
      '|'
    ) AS tag_array
  FROM `bigquery-public-data.stackoverflow.posts_questions`
  WHERE Tags IS NOT NULL
)

SELECT
  tag,
  SUM(cr.mentions) AS mention_count
FROM comment_refs      AS cr
JOIN question_tags     AS qt USING (question_id)
CROSS JOIN UNNEST(qt.tag_array) AS tag
GROUP BY tag
ORDER BY mention_count DESC, tag
LIMIT 10;