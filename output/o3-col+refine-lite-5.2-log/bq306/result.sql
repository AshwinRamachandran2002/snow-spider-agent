-- Top 10 tags for user 1908967 based on answers before 7 Jun 2018
WITH user_answers AS (
  SELECT
    id   AS answer_id,
    parent_id
  FROM `bigquery-public-data.stackoverflow.posts_answers`
  WHERE owner_user_id = 1908967
    AND creation_date < '2018-06-07'
),
vote_counts AS (
  SELECT
    ua.answer_id,
    ua.parent_id,
    SUM(CASE WHEN v.vote_type_id = 2 THEN 1 ELSE 0 END) AS upvotes,
    SUM(CASE WHEN v.vote_type_id = 1 THEN 1 ELSE 0 END) AS accepted
  FROM user_answers AS ua
  LEFT JOIN `bigquery-public-data.stackoverflow.votes` AS v
         ON v.post_id = ua.answer_id
  GROUP BY ua.answer_id, ua.parent_id
),
answer_tags AS (
  SELECT
    vc.answer_id,
    vc.upvotes,
    vc.accepted,
    tag
  FROM vote_counts AS vc
  JOIN `bigquery-public-data.stackoverflow.posts_questions` AS q
       ON q.id = vc.parent_id
  CROSS JOIN UNNEST(SPLIT(q.tags, '|')) AS tag
)
SELECT
  tag,
  SUM(10 * upvotes + 15 * accepted) AS total_score
FROM answer_tags
GROUP BY tag
ORDER BY total_score DESC
LIMIT 10;