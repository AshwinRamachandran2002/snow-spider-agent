WITH user_answers AS (
  -- all answers by the user before 7 Jun 2018
  SELECT id AS answer_id,
         parent_id AS question_id
  FROM `bigquery-public-data.stackoverflow.posts_answers`
  WHERE owner_user_id = 1908967
    AND creation_date < '2018-06-07'
),
votes_per_answer AS (
  -- count up-votes and accepted-answer votes for each answer
  SELECT
    ua.answer_id,
    SUM(CASE WHEN v.vote_type_id = 2 THEN 1 ELSE 0 END) AS upvotes,
    SUM(CASE WHEN v.vote_type_id = 1 THEN 1 ELSE 0 END) AS accepted_votes
  FROM user_answers AS ua
  LEFT JOIN `bigquery-public-data.stackoverflow.votes` AS v
         ON v.post_id = ua.answer_id
  GROUP BY ua.answer_id
),
answer_tags AS (
  -- split the question’s tag string into an array for each answer
  SELECT
    ua.answer_id,
    SPLIT(q.tags, '|') AS tag_arr
  FROM user_answers AS ua
  JOIN `bigquery-public-data.stackoverflow.posts_questions` AS q
       ON q.id = ua.question_id
)
-- aggregate the score (10·up + 15·accepted) per tag
SELECT
  tag,
  SUM(10 * v.upvotes + 15 * v.accepted_votes) AS total_score
FROM votes_per_answer AS v
JOIN answer_tags      AS t
     ON t.answer_id = v.answer_id
CROSS JOIN UNNEST(t.tag_arr) AS tag
GROUP BY tag
ORDER BY total_score DESC
LIMIT 10;