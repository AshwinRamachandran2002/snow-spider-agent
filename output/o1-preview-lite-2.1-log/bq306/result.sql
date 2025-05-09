WITH
  user_answers AS (
    SELECT
      a.id AS answer_id,
      a.parent_id AS question_id
    FROM
      `bigquery-public-data.stackoverflow.posts_answers` AS a
    WHERE
      a.owner_user_id = 1908967
      AND a.creation_date < '2018-06-07'
  ),
  upvotes_per_answer AS (
    SELECT
      v.post_id AS answer_id,
      COUNT(1) AS upvote_count
    FROM
      `bigquery-public-data.stackoverflow.votes` AS v
    WHERE
      v.vote_type_id = 2
      AND v.creation_date < '2018-06-07'
      AND v.post_id IN (SELECT answer_id FROM user_answers)
    GROUP BY
      v.post_id
  ),
  answers_with_tags AS (
    SELECT
      ua.answer_id,
      CASE
        WHEN q.accepted_answer_id = ua.answer_id THEN 1
        ELSE 0
      END AS is_accepted,
      q.tags
    FROM
      user_answers AS ua
    JOIN
      `bigquery-public-data.stackoverflow.posts_questions` AS q
    ON
      ua.question_id = q.id
  ),
  answers_with_upvotes AS (
    SELECT
      a.answer_id,
      a.is_accepted,
      a.tags,
      IFNULL(u.upvote_count, 0) AS upvote_count
    FROM
      answers_with_tags AS a
    LEFT JOIN
      upvotes_per_answer AS u
    ON
      a.answer_id = u.answer_id
  )
SELECT
  tag,
  SUM(10 * upvote_count + 15 * is_accepted) AS score
FROM
  answers_with_upvotes AS a
CROSS JOIN
  UNNEST(SPLIT(a.tags, '|')) AS tag
GROUP BY
  tag
ORDER BY
  score DESC
LIMIT
  10;