WITH
/*-----------------------------------------------------------
  1.  Questions with the data we need (view_count, owner, etc)
-----------------------------------------------------------*/
questions AS (
  SELECT
    id                    AS question_id,
    view_count            AS view_count,
    owner_user_id         AS owner_user_id,
    accepted_answer_id
  FROM `bigquery-public-data.stackoverflow.posts_questions`
  WHERE view_count IS NOT NULL                               -- ignore questions without a view‑count
),

/*-----------------------------------------------------------
  2.  All answers (only keep answers that have an owner)
-----------------------------------------------------------*/
answers AS (
  SELECT
    id,
    parent_id             AS question_id,
    owner_user_id,
    score
  FROM `bigquery-public-data.stackoverflow.posts_answers`
  WHERE owner_user_id IS NOT NULL
),

/*-----------------------------------------------------------
  3.  Per‑question answer statistics
      – total score of all answers
      – row_number() to know the 3 highest‑scoring answers
-----------------------------------------------------------*/
answer_stats AS (
  SELECT
    a.question_id,
    a.id                        AS answer_id,
    a.owner_user_id,
    a.score,
    ts.total_score,
    ROW_NUMBER() OVER (
        PARTITION BY a.question_id
        ORDER BY a.score DESC, a.id
    )                           AS rn                       -- 1,2,3 = top‑three answers
  FROM answers a
  JOIN (
        SELECT
          question_id,
          SUM(score) AS total_score
        FROM answers
        GROUP BY question_id
  ) ts
  ON ts.question_id = a.question_id
),

/*-----------------------------------------------------------
  4.  Build the set (question_id , user_id) that satisfies
      ANY of the association rules
-----------------------------------------------------------*/
assoc AS (
    /* 4.1  – question owner */
    SELECT question_id, owner_user_id AS user_id
    FROM questions
    WHERE owner_user_id IS NOT NULL

    UNION DISTINCT

    /* 4.2  – accepted answer owner */
    SELECT q.question_id, a.owner_user_id
    FROM questions q
    JOIN answers  a  ON a.id = q.accepted_answer_id
    WHERE a.owner_user_id IS NOT NULL

    UNION DISTINCT

    /* 4.3  – answers with score > 5 */
    SELECT question_id, owner_user_id
    FROM answer_stats
    WHERE score > 5

    UNION DISTINCT

    /* 4.4  – answers whose score is > 20 % of total answer score (and positive) */
    SELECT question_id, owner_user_id
    FROM answer_stats
    WHERE score > 0
      AND score > 0.20 * total_score

    UNION DISTINCT

    /* 4.5  – answers in the top‑three by score for the question */
    SELECT question_id, owner_user_id
    FROM answer_stats
    WHERE rn <= 3
),

/*-----------------------------------------------------------
  5.  Make every (user, question) pair unique
-----------------------------------------------------------*/
per_user_question AS (
  SELECT DISTINCT user_id, question_id
  FROM assoc
)

/*-----------------------------------------------------------
  6.  Sum the view counts of the associated questions
      and return the ten biggest totals
-----------------------------------------------------------*/
SELECT
  user_id,
  SUM(q.view_count) AS combined_view_count
FROM per_user_question puq
JOIN questions q
  ON q.question_id = puq.question_id
GROUP BY user_id
ORDER BY combined_view_count DESC
LIMIT 10;