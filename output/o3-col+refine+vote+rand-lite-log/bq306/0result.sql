-- Top-10 tags for user 1908967 based on answers written before 7 Jun 2018
WITH user_answers AS (
  SELECT
    a.id          AS answer_id,
    a.parent_id   AS question_id
  FROM `bigquery-public-data.stackoverflow.posts_answers` a
  WHERE a.owner_user_id = 1908967
    AND a.creation_date < '2018-06-07'
),
answer_votes AS (
  SELECT
    v.post_id                                            AS answer_id,
    SUM(CASE WHEN v.vote_type_id = 2 THEN 1 END) AS upvotes,          -- up-votes
    SUM(CASE WHEN v.vote_type_id = 1 THEN 1 END) AS accepted_votes    -- accepted-answer votes
  FROM `bigquery-public-data.stackoverflow.votes` v
  JOIN user_answers ua
        ON ua.answer_id = v.post_id
  WHERE v.vote_type_id IN (1, 2)      -- consider only up-votes and accepted-answer votes
  GROUP BY answer_id
),
answer_scores AS (
  SELECT
    ua.answer_id,
    ua.question_id,
    10 * IFNULL(av.upvotes,0) + 15 * IFNULL(av.accepted_votes,0) AS answer_score
  FROM user_answers ua
  LEFT JOIN answer_votes av
         USING (answer_id)
),
tag_scores AS (
  SELECT
    tag,
    SUM(answer_score) AS total_score
  FROM answer_scores a
  JOIN `bigquery-public-data.stackoverflow.posts_questions` q
        ON q.id = a.question_id
  CROSS JOIN UNNEST(SPLIT(q.tags, '|')) AS tag
  WHERE tag <> ''                      -- ignore empty tags, if any
  GROUP BY tag
)
SELECT
  tag,
  total_score
FROM tag_scores
ORDER BY total_score DESC
LIMIT 10;