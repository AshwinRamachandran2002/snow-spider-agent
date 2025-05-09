-- Top 10 tags for user 1908967 based on answers posted before 2018‑06‑07
WITH answers AS (
  SELECT
    id AS answer_id,
    parent_id AS question_id
  FROM `bigquery-public-data.stackoverflow.stackoverflow_posts`
  WHERE post_type_id = 2                       -- answers only
    AND owner_user_id = 1908967               -- the given user
    AND creation_date < TIMESTAMP('2018-06-07') -- posted before 07‑Jun‑2018
),
answer_votes AS (
  SELECT
    post_id AS answer_id,
    SUM(IF(vote_type_id = 2, 1, 0))  AS upvotes,   -- up‑votes
    SUM(IF(vote_type_id = 1, 1, 0))  AS accepted   -- accepted‑answer votes
  FROM `bigquery-public-data.stackoverflow.votes`
  WHERE vote_type_id IN (1,2)
    AND post_id IN (SELECT answer_id FROM answers)
  GROUP BY answer_id
),
answer_scores AS (
  SELECT
    a.answer_id,
    q.tags,
    10 * IFNULL(v.upvotes ,0) +
    15 * IFNULL(v.accepted,0)        AS score      -- weighted score
  FROM answers a
  LEFT JOIN answer_votes v USING(answer_id)
  LEFT JOIN `bigquery-public-data.stackoverflow.stackoverflow_posts` q
         ON q.id = a.question_id                   -- bring in question tags
),
tag_scores AS (
  SELECT
    tag,
    SUM(score) AS total_score
  FROM answer_scores,
       UNNEST(SPLIT(tags, '|')) AS tag             -- one row per tag
  WHERE tags IS NOT NULL
  GROUP BY tag
)
SELECT
  tag,
  total_score
FROM tag_scores
ORDER BY total_score DESC, tag
LIMIT 10;