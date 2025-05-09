WITH
/* all questions with basic fields we need */
q AS (
    SELECT
        "id",
        "owner_user_id",
        COALESCE("view_count",0)        AS "view_count",
        "accepted_answer_id"
    FROM STACKOVERFLOW.STACKOVERFLOW.POSTS_QUESTIONS
),

/* all answers with their score */
ans AS (
    SELECT
        "id",
        "parent_id",
        "owner_user_id",
        COALESCE("score",0)             AS "score"
    FROM STACKOVERFLOW.STACKOVERFLOW.POSTS_ANSWERS
),

/* total answer-score per question (for the 20 % rule) */
tot AS (
    SELECT
        "parent_id",
        SUM("score")                    AS "total_score"
    FROM ans
    GROUP BY "parent_id"
),

/* owners of the three highest-scoring answers to every question */
top3 AS (
    SELECT
        "parent_id",
        "owner_user_id"
    FROM (
        SELECT
            "parent_id",
            "owner_user_id",
            RANK() OVER (PARTITION BY "parent_id"
                         ORDER BY "score" DESC) AS rk
        FROM ans
    )
    WHERE rk <= 3
),

/* union of all five association rules */
assoc AS (
    /* 1. asker */
    SELECT  q."id"                     AS "question_id",
            q."owner_user_id"          AS "user_id"
    FROM q

    UNION

    /* 2. accepted-answer owner */
    SELECT  q."id",
            a."owner_user_id"
    FROM q
    JOIN ans a
      ON a."id" = q."accepted_answer_id"

    UNION

    /* 3. answers with score > 5 */
    SELECT  "parent_id",
            "owner_user_id"
    FROM ans
    WHERE "score" > 5

    UNION

    /* 4. answers whose score > 0 and > 20 % of total */
    SELECT  a."parent_id",
            a."owner_user_id"
    FROM ans a
    JOIN tot t
      ON t."parent_id" = a."parent_id"
    WHERE a."score" > 0
      AND a."score" > t."total_score" * 0.20

    UNION

    /* 5. owners of a top-3 answer */
    SELECT  "parent_id",
            "owner_user_id"
    FROM top3
),

/* accumulate view counts for every associated user */
user_views AS (
    SELECT
        assoc."user_id",
        SUM(q."view_count")             AS "combined_view_count"
    FROM assoc
    JOIN q
      ON q."id" = assoc."question_id"
    WHERE assoc."user_id" IS NOT NULL          -- skip anonymous/deleted users
    GROUP BY assoc."user_id"
)

/* final top-10 list */
SELECT
    u."id"                              AS "user_id",
    u."display_name",
    user_views."combined_view_count"
FROM user_views
JOIN STACKOVERFLOW.STACKOVERFLOW.USERS u
  ON u."id" = user_views."user_id"
ORDER BY user_views."combined_view_count" DESC NULLS LAST
LIMIT 10;