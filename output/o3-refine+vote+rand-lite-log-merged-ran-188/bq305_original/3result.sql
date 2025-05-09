-- Top 10 users with the highest total view‑counts of questions they are
-- “associated” with (see definition in the task description).

WITH
-- 1.  Basic information about every question
questions AS (
  SELECT
    id                         AS qid,
    COALESCE(view_count,0)     AS view_cnt,
    owner_user_id              AS q_owner,
    accepted_answer_id         AS acc_ans_id
  FROM `bigquery-public-data.stackoverflow.posts_questions`
),

-- 2.  All answers together with the question they belong to
answers AS (
  SELECT
    id                AS ans_id,
    parent_id         AS qid,
    owner_user_id     AS a_owner,
    COALESCE(score,0) AS score
  FROM `bigquery-public-data.stackoverflow.posts_answers`
  WHERE parent_id IS NOT NULL
),

-- 3.  Total score of all answers per question
total_answer_scores AS (
  SELECT
    qid,
    SUM(score) AS total_score
  FROM answers
  GROUP BY qid
),

-- 4.  Answers enriched with question‑level data and ranked by score
ranked_answers AS (
  SELECT
    a.*,
    q.acc_ans_id,
    tas.total_score,
    ROW_NUMBER() OVER (PARTITION BY a.qid
                       ORDER BY a.score DESC, a.ans_id) AS score_rank
  FROM answers a
  LEFT JOIN total_answer_scores tas USING (qid)
  LEFT JOIN questions            q   USING (qid)
),

-- 5.  Answers whose owners are “associated” with the question
eligible_answer_associations AS (
  SELECT DISTINCT
    qid,
    a_owner AS user_id
  FROM ranked_answers
  WHERE
        ans_id = acc_ans_id                    -- accepted answer
     OR score > 5                              -- score > 5
     OR (score > 0 AND score > 0.2*total_score) -- >20 % of total answer score
     OR score_rank <= 3                        -- in top 3 scores
     AND a_owner IS NOT NULL
),

-- 6.  Question owners are automatically associated
question_owner_associations AS (
  SELECT DISTINCT
    qid,
    q_owner AS user_id
  FROM questions
  WHERE q_owner IS NOT NULL
),

-- 7.  Union all associations, one row per (question,user)
all_associations AS (
  SELECT * FROM question_owner_associations
  UNION DISTINCT
  SELECT * FROM eligible_answer_associations
),

-- 8.  Sum view counts of the associated questions per user
user_view_totals AS (
  SELECT
    user_id,
    SUM(q.view_cnt) AS total_views
  FROM all_associations a
  JOIN questions     q USING (qid)
  GROUP BY user_id
)

-- 9.  Top 10 users
SELECT
  user_id,
  total_views
FROM user_view_totals
ORDER BY total_views DESC
LIMIT 10;