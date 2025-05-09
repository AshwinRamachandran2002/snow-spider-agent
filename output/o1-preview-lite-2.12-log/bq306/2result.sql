SELECT tag,
  SUM(10 * upvotes + 15 * accepted_answers) AS Score
FROM (
  SELECT a.id AS answer_id,
    a.parent_id,
    COALESCE(SUM(IF(v.vote_type_id = 2, 1, 0)), 0) AS upvotes,
    COALESCE(SUM(IF(v.vote_type_id = 1, 1, 0)), 0) AS accepted_answers
  FROM `bigquery-public-data.stackoverflow.posts_answers` AS a
  LEFT JOIN `bigquery-public-data.stackoverflow.votes` AS v
    ON a.id = v.post_id AND v.vote_type_id IN (1, 2)
  WHERE a.owner_user_id = 1908967
    AND a.creation_date < '2018-06-07'
  GROUP BY a.id, a.parent_id
) AS av
JOIN `bigquery-public-data.stackoverflow.posts_questions` AS q
  ON av.parent_id = q.id
CROSS JOIN UNNEST(SPLIT(REGEXP_REPLACE(q.tags, r'^<|>$', ''), '><')) AS tag
GROUP BY tag
ORDER BY Score DESC
LIMIT 10;