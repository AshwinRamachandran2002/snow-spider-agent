SELECT
  tag,
  (10 * upvotes) + (15 * accepted_answers) AS score
FROM (
  SELECT
    tag,
    SUM(upvotes) AS upvotes,
    SUM(accepted_answers) AS accepted_answers
  FROM (
    -- From user's questions
    SELECT
      tag,
      COUNT(v.id) AS upvotes,
      0 AS accepted_answers
    FROM
      `bigquery-public-data.stackoverflow.posts_questions` pq
      LEFT JOIN `bigquery-public-data.stackoverflow.votes` v
        ON pq.id = v.post_id
        AND v.vote_type_id = 2
        AND v.creation_date < '2018-06-07'
      , UNNEST(SPLIT(REGEXP_REPLACE(pq.tags, r'^<|>$', ''), '><')) AS tag
    WHERE
      pq.owner_user_id = 1908967
      AND pq.creation_date < '2018-06-07'
    GROUP BY
      tag

    UNION ALL

    -- From user's answers
    SELECT
      tag,
      COUNT(v.id) AS upvotes,
      SUM(CASE WHEN pa.id = pq.accepted_answer_id THEN 1 ELSE 0 END) AS accepted_answers
    FROM
      `bigquery-public-data.stackoverflow.posts_answers` pa
    JOIN `bigquery-public-data.stackoverflow.posts_questions` pq
      ON pa.parent_id = pq.id
    LEFT JOIN `bigquery-public-data.stackoverflow.votes` v
      ON pa.id = v.post_id
      AND v.vote_type_id = 2
      AND v.creation_date < '2018-06-07'
      , UNNEST(SPLIT(REGEXP_REPLACE(pq.tags, r'^<|>$', ''), '><')) AS tag
    WHERE
      pa.owner_user_id = 1908967
      AND pa.creation_date < '2018-06-07'
    GROUP BY
      tag
  ) AS combined
  GROUP BY
    tag
) AS final
ORDER BY
  score DESC
LIMIT
  10;