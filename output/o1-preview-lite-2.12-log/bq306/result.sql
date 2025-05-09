WITH user_answers AS (
  SELECT id AS answer_id, parent_id
  FROM `bigquery-public-data.stackoverflow.posts_answers`
  WHERE owner_user_id = 1908967
    AND creation_date < '2018-06-07'
),
answer_votes AS (
  SELECT ua.answer_id,
    SUM(CASE WHEN v.vote_type_id = 2 THEN 1 ELSE 0 END) AS upvotes,
    SUM(CASE WHEN v.vote_type_id = 1 THEN 1 ELSE 0 END) AS accepts
  FROM user_answers ua
  LEFT JOIN `bigquery-public-data.stackoverflow.votes` v
    ON ua.answer_id = v.post_id
       AND v.vote_type_id IN (1, 2)
  GROUP BY ua.answer_id
),
answer_tags AS (
  SELECT ua.answer_id,
    SPLIT(q.tags, '|') AS tag_list
  FROM user_answers ua
  INNER JOIN `bigquery-public-data.stackoverflow.posts_questions` q
    ON ua.parent_id = q.id
),
answer_tag_scores AS (
  SELECT ats.answer_id,
    tag,
    av.upvotes,
    av.accepts,
    (10 * av.upvotes) + (15 * av.accepts) AS score
  FROM answer_tags ats
  JOIN answer_votes av
    ON ats.answer_id = av.answer_id
  CROSS JOIN UNNEST(ats.tag_list) AS tag
)
SELECT tag,
  SUM(score) AS Score
FROM answer_tag_scores
GROUP BY tag
ORDER BY Score DESC
LIMIT 10;