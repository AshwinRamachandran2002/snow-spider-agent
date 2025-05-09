WITH
-- 1. asker of every question
askers AS (
    SELECT
        q."id"             AS question_id,
        q."owner_user_id"  AS user_id
    FROM STACKOVERFLOW.STACKOVERFLOW.POSTS_QUESTIONS q
    WHERE q."owner_user_id" IS NOT NULL
),

-- 2. users whose answer was accepted
accepted_answerers AS (
    SELECT
        q."id"            AS question_id,
        a."owner_user_id" AS user_id
    FROM STACKOVERFLOW.STACKOVERFLOW.POSTS_QUESTIONS q
    JOIN STACKOVERFLOW.STACKOVERFLOW.POSTS_ANSWERS a
          ON q."accepted_answer_id" = a."id"
    WHERE a."owner_user_id" IS NOT NULL
),

-- 3. answers with score > 5
high_score_answers AS (
    SELECT
        a."parent_id"     AS question_id,
        a."owner_user_id" AS user_id
    FROM STACKOVERFLOW.STACKOVERFLOW.POSTS_ANSWERS a
    WHERE a."score" > 5
      AND a."owner_user_id" IS NOT NULL
),

-- 4. answers whose score share > 20 % of total positive score
share_gt_20 AS (
    SELECT
        question_id,
        user_id
    FROM (
        SELECT
            a."parent_id"                     AS question_id,
            a."owner_user_id"                 AS user_id,
            a."score" /
            SUM(a."score") OVER (PARTITION BY a."parent_id") AS pct_share
        FROM STACKOVERFLOW.STACKOVERFLOW.POSTS_ANSWERS a
        WHERE a."score" > 0
          AND a."owner_user_id" IS NOT NULL
    )
    WHERE pct_share > 0.20
),

-- 5. top-3 highest-scoring answers per question
top3_answers AS (
    SELECT
        question_id,
        user_id
    FROM (
        SELECT
            a."parent_id"     AS question_id,
            a."owner_user_id" AS user_id,
            ROW_NUMBER() OVER (PARTITION BY a."parent_id"
                               ORDER BY a."score" DESC, a."id") AS rn
        FROM STACKOVERFLOW.STACKOVERFLOW.POSTS_ANSWERS a
        WHERE a."owner_user_id" IS NOT NULL
    )
    WHERE rn <= 3
),

-- union of all (question,user) associations
associations AS (
    SELECT * FROM askers
    UNION
    SELECT * FROM accepted_answerers
    UNION
    SELECT * FROM high_score_answers
    UNION
    SELECT * FROM share_gt_20
    UNION
    SELECT * FROM top3_answers
),

-- aggregate total views per user across associated questions
user_totals AS (
    SELECT
        a.user_id,
        SUM(COALESCE(q."view_count",0)) AS total_views
    FROM associations a
    JOIN STACKOVERFLOW.STACKOVERFLOW.POSTS_QUESTIONS q
          ON q."id" = a.question_id
    GROUP BY a.user_id
)

-- final top-10 users
SELECT
    u."id"            AS user_id,
    u."display_name",
    t.total_views
FROM user_totals t
LEFT JOIN STACKOVERFLOW.STACKOVERFLOW.USERS u
       ON u."id" = t.user_id
ORDER BY t.total_views DESC NULLS LAST
LIMIT 10;