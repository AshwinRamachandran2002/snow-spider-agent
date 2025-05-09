SELECT
  tag,
  (10 * COUNTIF(v.vote_type_id = 2)) + (15 * COUNTIF(v.vote_type_id = 1)) AS Score
FROM
  `bigquery-public-data.stackoverflow.posts_answers` AS a
LEFT JOIN
  `bigquery-public-data.stackoverflow.votes` AS v
  ON a.id = v.post_id AND v.vote_type_id IN (1, 2)
JOIN
  `bigquery-public-data.stackoverflow.posts_questions` AS q
  ON a.parent_id = q.id
CROSS JOIN
  UNNEST(SPLIT(q.tags, '|')) AS tag
WHERE
  a.owner_user_id = 1908967
  AND a.creation_date < '2018-06-07'
GROUP BY
  tag
ORDER BY
  Score DESC
LIMIT 10;