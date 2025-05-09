WITH user_answers AS (
  -- answers written by the user before 7 Jun 2018
  SELECT
    id           AS answer_id,
    parent_id    AS question_id
  FROM `bigquery-public-data.stackoverflow.posts_answers`
  WHERE owner_user_id = 1908967
    AND creation_date < '2018-06-07'
),
answer_votes AS (
  -- up-votes (type 2) and accepted-answer marks (type 1) on those answers
  SELECT
    post_id                    AS answer_id,
    SUM(IF(vote_type_id = 2, 1, 0)) AS upvotes,
    SUM(IF(vote_type_id = 1, 1, 0)) AS accepted_marks
  FROM `bigquery-public-data.stackoverflow.votes`
  WHERE vote_type_id IN (1,2)
    AND post_id IN (SELECT answer_id FROM user_answers)
  GROUP BY post_id
),
answer_scores AS (
  -- combine answers with their vote counts
  SELECT
    ua.answer_id,
    ua.question_id,
    COALESCE(av.upvotes, 0)        AS upvotes,
    COALESCE(av.accepted_marks, 0) AS accepted_marks
  FROM user_answers ua
  LEFT JOIN answer_votes av USING (answer_id)
)
-- aggregate the weighted scores per tag and pick top 10
SELECT
  tag,
  SUM(10 * upvotes + 15 * accepted_marks) AS total_score
FROM answer_scores a
JOIN `bigquery-public-data.stackoverflow.posts_questions` q
  ON q.id = a.question_id
CROSS JOIN UNNEST(SPLIT(q.tags, '|')) AS tag
GROUP BY tag
ORDER BY total_score DESC
LIMIT 10;