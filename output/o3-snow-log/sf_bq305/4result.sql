WITH
q AS (   -- questions with basic data
  SELECT
      "id"                    AS question_id,
      "view_count",
      "owner_user_id",
      "accepted_answer_id"
  FROM STACKOVERFLOW.STACKOVERFLOW."POSTS_QUESTIONS"
  WHERE "view_count" IS NOT NULL
),

a AS (   -- answers with basic data
  SELECT
      "id"          AS "answer_id",
      "parent_id"   AS question_id,
      "owner_user_id",
      "score"
  FROM STACKOVERFLOW.STACKOVERFLOW."POSTS_ANSWERS"
),

total_scores AS (   -- total answer-score per question
  SELECT
      question_id,
      SUM("score") AS total_score
  FROM a
  GROUP BY question_id
),

/* -------- association rules -------- */
owner_assoc AS (   -- 1: question owner
  SELECT
      question_id,
      "owner_user_id" AS user_id
  FROM q
  WHERE "owner_user_id" IS NOT NULL
),

accepted_assoc AS (  -- 2: accepted-answer owner
  SELECT
      q.question_id,
      a."owner_user_id" AS user_id
  FROM q
  JOIN a
    ON a."answer_id" = q."accepted_answer_id"
  WHERE a."owner_user_id" IS NOT NULL
),

highscore_assoc AS ( -- 3: answers with score > 5
  SELECT
      question_id,
      "owner_user_id" AS user_id
  FROM a
  WHERE "score" > 5
    AND "owner_user_id" IS NOT NULL
),

above20_assoc AS (   -- 4: answer score > 20 % of total (and >0)
  SELECT
      a.question_id,
      a."owner_user_id" AS user_id
  FROM a
  JOIN total_scores t
    ON t.question_id = a.question_id
  WHERE a."score" > 0
    AND a."score" > 0.2 * t.total_score
    AND a."owner_user_id" IS NOT NULL
),

top3_assoc AS (      -- 5: top-3 scoring answers per question
  SELECT
      question_id,
      "owner_user_id" AS user_id
  FROM (
        SELECT
            question_id,
            "owner_user_id",
            ROW_NUMBER() OVER (PARTITION BY question_id
                               ORDER BY "score" DESC, "answer_id") AS rn
        FROM a
       )
  WHERE rn <= 3
    AND "owner_user_id" IS NOT NULL
),

/* union all association sets, then distinct */
all_assoc AS (
  SELECT DISTINCT question_id, user_id FROM (
        SELECT * FROM owner_assoc
        UNION ALL
        SELECT * FROM accepted_assoc
        UNION ALL
        SELECT * FROM highscore_assoc
        UNION ALL
        SELECT * FROM above20_assoc
        UNION ALL
        SELECT * FROM top3_assoc
  )
),

/* sum view-counts for every associated user */
user_views AS (
  SELECT
      user_id,
      SUM(q."view_count") AS total_views
  FROM all_assoc
  JOIN q
    ON q.question_id = all_assoc.question_id
  GROUP BY user_id
)

/* -------- final result -------- */
SELECT
    user_id,
    total_views
FROM user_views
ORDER BY total_views DESC NULLS LAST
LIMIT 10;