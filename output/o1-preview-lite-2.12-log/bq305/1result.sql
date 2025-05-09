SELECT
      associated_users.user_id,
      SUM(associated_questions.view_count) AS combined_view_count
FROM (
  SELECT
    owner_user_id AS user_id,
    id AS question_id
  FROM
    `bigquery-public-data.stackoverflow.posts_questions`
  WHERE
    owner_user_id IS NOT NULL

  UNION DISTINCT

  SELECT
    a.owner_user_id AS user_id,
    a.parent_id AS question_id
  FROM
    `bigquery-public-data.stackoverflow.posts_answers` a
  WHERE
    a.score > 5
    AND a.owner_user_id IS NOT NULL

  UNION DISTINCT

  SELECT
    a.owner_user_id AS user_id,
    a.parent_id AS question_id
  FROM
    `bigquery-public-data.stackoverflow.posts_answers` a
  JOIN (
    SELECT
      parent_id,
      SUM(score) AS total_score
    FROM
      `bigquery-public-data.stackoverflow.posts_answers`
    GROUP BY
      parent_id
  ) ts
  ON
    a.parent_id = ts.parent_id
  WHERE
    a.score > 0.2 * ts.total_score
    AND a.score > 0
    AND a.owner_user_id IS NOT NULL

  UNION DISTINCT

  SELECT
    a.owner_user_id AS user_id,
    a.parent_id AS question_id
  FROM (
    SELECT
      parent_id,
      id,
      owner_user_id,
      score,
      RANK() OVER (PARTITION BY parent_id ORDER BY score DESC) AS rank
    FROM
      `bigquery-public-data.stackoverflow.posts_answers`
    WHERE
      owner_user_id IS NOT NULL
  ) a
  WHERE
    rank <= 3

  UNION DISTINCT

  SELECT
    a.owner_user_id AS user_id,
    q.id AS question_id
  FROM
    `bigquery-public-data.stackoverflow.posts_answers` a
  JOIN
    `bigquery-public-data.stackoverflow.posts_questions` q
  ON
    q.accepted_answer_id = a.id
  WHERE
    a.owner_user_id IS NOT NULL
) AS associated_users
JOIN
  `bigquery-public-data.stackoverflow.posts_questions` AS associated_questions
ON
  associated_users.question_id = associated_questions.id
GROUP BY
  associated_users.user_id
ORDER BY
  combined_view_count DESC
LIMIT 10;