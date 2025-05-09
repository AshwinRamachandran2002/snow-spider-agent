WITH
/* all questions we will work with */
"q" AS (
    SELECT
        "id"                AS "question_id",
        "owner_user_id"     AS "question_owner",
        COALESCE("view_count",0) AS "view_count",
        "accepted_answer_id"
    FROM STACKOVERFLOW.STACKOVERFLOW.POSTS_QUESTIONS
),

/* all answers */
"a" AS (
    SELECT
        "id"                AS "answer_id",
        "parent_id"         AS "question_id",
        "owner_user_id"     AS "answer_owner",
        COALESCE("score",0) AS "score"
    FROM STACKOVERFLOW.STACKOVERFLOW.POSTS_ANSWERS
    WHERE "owner_user_id" IS NOT NULL
),

/* total answer score per question                               */
"totals" AS (
    SELECT
        "question_id",
        SUM("score")   AS "total_score"
    FROM "a"
    GROUP BY "question_id"
),

/* top-3 highest-scoring answers (ties handled by DENSE_RANK)    */
"top3" AS (
    SELECT
        "question_id",
        "answer_owner" AS "user_id"
    FROM (
        SELECT
            "question_id",
            "answer_owner",
            DENSE_RANK() OVER (PARTITION BY "question_id"
                               ORDER BY "score" DESC) AS "rnk"
        FROM "a"
    )
    WHERE "rnk" <= 3
),

/* answers whose score is > 20 % of total positive score         */
"big_share" AS (
    SELECT
        a."question_id",
        a."answer_owner" AS "user_id"
    FROM "a"  a
    JOIN "totals" t
          ON a."question_id" = t."question_id"
    WHERE a."score" > 0
      AND a."score" >= 0.20 * t."total_score"
),

/* accepted-answer owners                                         */
"accepted" AS (
    SELECT
        q."question_id",
        a."answer_owner" AS "user_id"
    FROM "q" q
    JOIN "a" a
      ON q."accepted_answer_id" = a."answer_id"
),

/* answers with score > 5                                         */
"score_gt5" AS (
    SELECT
        "question_id",
        "answer_owner" AS "user_id"
    FROM "a"
    WHERE "score" > 5
),

/* assemble every (question,user) association, one row each       */
"associations" AS (
    SELECT "question_id", "question_owner" AS "user_id" FROM "q"
    UNION
    SELECT * FROM "accepted"
    UNION
    SELECT * FROM "score_gt5"
    UNION
    SELECT * FROM "big_share"
    UNION
    SELECT * FROM "top3"
),

/* deduplicate & attach view counts                               */
"user_question_views" AS (
    SELECT DISTINCT
        a."user_id",
        a."question_id",
        q."view_count"
    FROM "associations" a
    JOIN "q" q
      ON a."question_id" = q."question_id"
),

/* sum view counts per user                                       */
"user_totals" AS (
    SELECT
        "user_id",
        SUM("view_count") AS "combined_view_count"
    FROM "user_question_views"
    GROUP BY "user_id"
),

/* pick top 10 users                                              */
"top10" AS (
    SELECT
        "user_id",
        "combined_view_count"
    FROM "user_totals"
    ORDER BY "combined_view_count" DESC NULLS LAST
    LIMIT 10
)

/* final output with display names                                */
SELECT
    t."user_id",
    u."display_name",
    t."combined_view_count"
FROM "top10" t
LEFT JOIN STACKOVERFLOW.STACKOVERFLOW.USERS u
       ON t."user_id" = u."id"
ORDER BY t."combined_view_count" DESC NULLS LAST;