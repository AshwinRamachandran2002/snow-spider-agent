WITH total_scores AS (         -- total answer score per question
  SELECT parent_id AS question_id,
         SUM(score) AS total_score
  FROM `bigquery-public-data.stackoverflow.posts_answers`
  GROUP BY question_id
),
ranked_answers AS (            -- rank answers by score per question
  SELECT id,
         parent_id AS question_id,
         owner_user_id,
         score,
         ROW_NUMBER() OVER (PARTITION BY parent_id ORDER BY score DESC, id) AS answer_rank
  FROM `bigquery-public-data.stackoverflow.posts_answers`
),
qualifying_answer_users AS (   -- users whose answers satisfy any of the 4 rules
  SELECT DISTINCT
         ra.question_id,
         ra.owner_user_id
  FROM ranked_answers ra
  JOIN `bigquery-public-data.stackoverflow.posts_questions` q
        ON q.id = ra.question_id
  LEFT JOIN total_scores ts
        ON ts.question_id = ra.question_id
  WHERE ra.owner_user_id IS NOT NULL
    AND (
         ra.id = q.accepted_answer_id                 -- accepted answer
      OR ra.score > 5                                 -- score > 5
      OR (ra.score > 0 AND ra.score > 0.20 * ts.total_score)   -- >20 % of total
      OR ra.answer_rank <= 3                          -- in top-3 by score
    )
),
question_owners AS (           -- owners of the questions
  SELECT id AS question_id,
         owner_user_id
  FROM `bigquery-public-data.stackoverflow.posts_questions`
  WHERE owner_user_id IS NOT NULL
),
associated_users AS (          -- union of both association sources
  SELECT * FROM qualifying_answer_users
  UNION DISTINCT
  SELECT * FROM question_owners
),
user_question_views AS (       -- attach view counts
  SELECT
    au.owner_user_id,
    q.view_count
  FROM associated_users au
  JOIN `bigquery-public-data.stackoverflow.posts_questions` q
    ON q.id = au.question_id
  WHERE q.view_count IS NOT NULL
),
user_total_views AS (          -- total views per user
  SELECT
    owner_user_id,
    SUM(view_count) AS total_views
  FROM user_question_views
  GROUP BY owner_user_id
)
SELECT
  u.display_name,
  tv.owner_user_id AS user_id,
  tv.total_views
FROM user_total_views tv
JOIN `bigquery-public-data.stackoverflow.users` u
  ON u.id = tv.owner_user_id
ORDER BY tv.total_views DESC
LIMIT 10;