WITH
/*--------------------------------------------------------------*
 |  Rule 1 – the question owner                                 |
 *--------------------------------------------------------------*/
owners AS (
  SELECT
    id            AS question_id,
    owner_user_id AS user_id
  FROM
    `bigquery-public-data.stackoverflow.posts_questions`
  WHERE
    owner_user_id IS NOT NULL
),

/*--------------------------------------------------------------*
 |  Rule 2 – author of the accepted answer                      |
 *--------------------------------------------------------------*/
accepted AS (
  SELECT
    q.id            AS question_id,
    a.owner_user_id AS user_id
  FROM
    `bigquery-public-data.stackoverflow.posts_questions`  q
  JOIN
    `bigquery-public-data.stackoverflow.posts_answers`    a
  ON
    q.accepted_answer_id = a.id
  WHERE
    a.owner_user_id IS NOT NULL
),

/*--------------------------------------------------------------*
 |  Rule 3 – answers with score > 5                             |
 *--------------------------------------------------------------*/
score_gt5 AS (
  SELECT
    parent_id     AS question_id,
    owner_user_id AS user_id
  FROM
    `bigquery-public-data.stackoverflow.posts_answers`
  WHERE
    score > 5
    AND owner_user_id IS NOT NULL
),

/*--------------------------------------------------------------*
 |  Rule 4 – three highest‑scoring answers per question         |
 *--------------------------------------------------------------*/
top3 AS (
  SELECT
    parent_id     AS question_id,
    owner_user_id AS user_id
  FROM (
    SELECT
      parent_id,
      owner_user_id,
      ROW_NUMBER() OVER (PARTITION BY parent_id ORDER BY score DESC) AS rnk
    FROM
      `bigquery-public-data.stackoverflow.posts_answers`
    WHERE
      owner_user_id IS NOT NULL
      AND score IS NOT NULL
  )
  WHERE
    rnk <= 3
),

/*--------------------------------------------------------------*
 |  Rule 5 – answers > 0 and > 20 % of total positive score     |
 *--------------------------------------------------------------*/
pct20 AS (
  WITH totals AS (
    SELECT
      parent_id  AS question_id,
      SUM(score) AS total_positive
    FROM
      `bigquery-public-data.stackoverflow.posts_answers`
    WHERE
      score > 0
    GROUP BY
      parent_id
  )
  SELECT
    a.parent_id     AS question_id,
    a.owner_user_id AS user_id
  FROM
    `bigquery-public-data.stackoverflow.posts_answers` a
  JOIN
    totals t
  ON
    a.parent_id = t.question_id
  WHERE
    a.score > 0
    AND a.score > 0.20 * t.total_positive
    AND a.owner_user_id IS NOT NULL
),

/*--------------------------------------------------------------*
 |  Union of all associations                                   |
 *--------------------------------------------------------------*/
assoc AS (
  SELECT DISTINCT * FROM owners
  UNION DISTINCT SELECT * FROM accepted
  UNION DISTINCT SELECT * FROM score_gt5
  UNION DISTINCT SELECT * FROM top3
  UNION DISTINCT SELECT * FROM pct20
)

/*--------------------------------------------------------------*
 |  Aggregate view counts and return top 10 users               |
 *--------------------------------------------------------------*/
SELECT
  u.id                AS user_id,
  u.display_name      AS user_display_name,
  SUM(q.view_count)   AS combined_view_count
FROM
  assoc a
JOIN
  `bigquery-public-data.stackoverflow.posts_questions` q
ON
  a.question_id = q.id
JOIN
  `bigquery-public-data.stackoverflow.users` u
ON
  a.user_id = u.id
WHERE
  q.view_count IS NOT NULL
GROUP BY
  user_id, user_display_name
ORDER BY
  combined_view_count DESC,
  user_id ASC
LIMIT 10;