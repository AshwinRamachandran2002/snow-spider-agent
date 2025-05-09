-- Top 10 users by combined view‑count of questions they are “associated” with
WITH
-- questions we will work with
questions AS (
  SELECT
    id                                   AS qid,
    COALESCE(view_count,0)               AS view_cnt,
    owner_user_id                        AS q_owner,
    accepted_answer_id                   AS acc_ans_id
  FROM `bigquery-public-data.stackoverflow.posts_questions`
),

-- answers plus some per‑question aggregates we need
answers_enriched AS (
  SELECT
    a.id                                 AS aid,
    a.parent_id                          AS qid,
    a.owner_user_id                      AS a_owner,
    a.score                              AS a_score,
    -- total answer score for the question
    SUM(COALESCE(a.score,0))
      OVER (PARTITION BY a.parent_id)    AS tot_score,
    -- ranking of answers by score within each question
    ROW_NUMBER()
      OVER (PARTITION BY a.parent_id
            ORDER BY a.score DESC, a.id) AS rn
  FROM `bigquery-public-data.stackoverflow.posts_answers` a
),

-- every (user,question) pair that satisfies at least one association rule
associations AS (
  -- 1. owners of the question itself
  SELECT q_owner                AS user_id, qid, view_cnt FROM questions
  WHERE q_owner IS NOT NULL
  
  UNION ALL
  
  -- 2. user whose answer is the accepted answer
  SELECT a.a_owner              AS user_id, a.qid, q.view_cnt
  FROM answers_enriched a
  JOIN questions q ON q.qid = a.qid
  WHERE a.aid = q.acc_ans_id
        AND a.a_owner IS NOT NULL
  
  UNION ALL
  
  -- 3. answers with score > 5
  SELECT a.a_owner, a.qid, q.view_cnt
  FROM answers_enriched a
  JOIN questions q ON q.qid = a.qid
  WHERE a.a_score > 5
        AND a.a_owner IS NOT NULL
  
  UNION ALL
  
  -- 4. answers whose score > 0 and > 20 % of total answer score
  SELECT a.a_owner, a.qid, q.view_cnt
  FROM answers_enriched a
  JOIN questions q ON q.qid = a.qid
  WHERE a.a_score > 0
        AND a.a_score > 0.2 * a.tot_score
        AND a.a_owner IS NOT NULL
  
  UNION ALL
  
  -- 5. answers that are among the top‑3 scoring for the question
  SELECT a.a_owner, a.qid, q.view_cnt
  FROM answers_enriched a
  JOIN questions q ON q.qid = a.qid
  WHERE a.rn <= 3
        AND a.a_owner IS NOT NULL
),

-- keep each (user,question) only once
distinct_assoc AS (
  SELECT DISTINCT user_id, qid, view_cnt FROM associations
)

-- final aggregation: total question views per user
SELECT
  u.id                AS user_id,
  u.display_name,
  SUM(view_cnt)       AS total_question_views
FROM distinct_assoc da
JOIN `bigquery-public-data.stackoverflow.users` u
  ON u.id = da.user_id
GROUP BY user_id, display_name
ORDER BY total_question_views DESC
LIMIT 10;