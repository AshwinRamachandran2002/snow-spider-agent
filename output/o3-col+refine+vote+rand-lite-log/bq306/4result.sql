WITH answers AS (
  -- all answers by the user before 7 Jun 2018
  SELECT
    a.id         AS answer_id,
    a.parent_id  AS question_id
  FROM `bigquery-public-data.stackoverflow.posts_answers` AS a
  WHERE a.owner_user_id = 1908967
    AND a.creation_date < '2018-06-07'
),
votes_per_answer AS (
  -- count up-votes (type 2) and accept-votes (type 1) for each answer
  SELECT
    ans.answer_id,
    SUM(IF(v.vote_type_id = 2, 1, 0)) AS upvotes,
    SUM(IF(v.vote_type_id = 1, 1, 0)) AS accepts
  FROM answers AS ans
  LEFT JOIN `bigquery-public-data.stackoverflow.votes` AS v
         ON v.post_id = ans.answer_id
        AND v.vote_type_id IN (1, 2)
  GROUP BY ans.answer_id
)
SELECT
  tag,
  SUM(10 * upvotes + 15 * accepts) AS total_score
FROM votes_per_answer AS v
JOIN answers AS a
  ON a.answer_id = v.answer_id
JOIN `bigquery-public-data.stackoverflow.posts_questions` AS q
  ON q.id = a.question_id
CROSS JOIN UNNEST(SPLIT(q.tags, '|')) AS tag
WHERE tag IS NOT NULL AND tag <> ''
GROUP BY tag
ORDER BY total_score DESC
LIMIT 10;