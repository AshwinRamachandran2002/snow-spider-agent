WITH
/* 1) question owners -------------------------------------------------------*/
q_owner AS (
    SELECT 
        "id"            AS "question_id",
        "owner_user_id" AS "user_id"
    FROM STACKOVERFLOW.STACKOVERFLOW."POSTS_QUESTIONS"
    WHERE "owner_user_id" IS NOT NULL
),

/* 2) owners of accepted answers -------------------------------------------*/
accepted_ans AS (
    SELECT 
        q."id"          AS "question_id",
        a."owner_user_id" AS "user_id"
    FROM STACKOVERFLOW.STACKOVERFLOW."POSTS_QUESTIONS" q
    JOIN STACKOVERFLOW.STACKOVERFLOW."POSTS_ANSWERS"  a
          ON q."accepted_answer_id" = a."id"
    WHERE a."owner_user_id" IS NOT NULL
),

/* 3) answers whose score > 5 ----------------------------------------------*/
score_gt5 AS (
    SELECT 
        "parent_id"     AS "question_id",
        "owner_user_id" AS "user_id"
    FROM STACKOVERFLOW.STACKOVERFLOW."POSTS_ANSWERS"
    WHERE "score" > 5 
      AND "owner_user_id" IS NOT NULL
),

/* helper: total answer score per question ----------------------------------*/
totals AS (
    SELECT 
        "parent_id"     AS "question_id",
        SUM("score")    AS total_score
    FROM STACKOVERFLOW.STACKOVERFLOW."POSTS_ANSWERS"
    GROUP BY "parent_id"
),

/* 4) answers >0 and >20% of total score -----------------------------------*/
score_gt20pct AS (
    SELECT 
        a."parent_id"     AS "question_id",
        a."owner_user_id" AS "user_id"
    FROM STACKOVERFLOW.STACKOVERFLOW."POSTS_ANSWERS" a
    JOIN totals t
         ON a."parent_id" = t."question_id"
    WHERE a."score" > 0
      AND a."score" > t.total_score * 0.20
      AND a."owner_user_id" IS NOT NULL
),

/* 5) owners of top-3 highest-scoring answers per question ------------------*/
top3 AS (
    SELECT 
        "parent_id"     AS "question_id",
        "owner_user_id" AS "user_id"
    FROM (
        SELECT
            "parent_id",
            "owner_user_id",
            ROW_NUMBER() OVER (PARTITION BY "parent_id"
                               ORDER BY "score" DESC, "id") AS rn
        FROM STACKOVERFLOW.STACKOVERFLOW."POSTS_ANSWERS"
        WHERE "owner_user_id" IS NOT NULL
    )
    WHERE rn <= 3
),

/* union of all association rules (duplicates removed) ----------------------*/
all_pairs AS (
    SELECT * FROM q_owner
    UNION
    SELECT * FROM accepted_ans
    UNION
    SELECT * FROM score_gt5
    UNION
    SELECT * FROM score_gt20pct
    UNION
    SELECT * FROM top3
),

/* sum of question view counts per user -------------------------------------*/
user_view_totals AS (
    SELECT 
        p."user_id",
        SUM(q."view_count") AS total_views
    FROM all_pairs p
    JOIN STACKOVERFLOW.STACKOVERFLOW."POSTS_QUESTIONS" q
          ON p."question_id" = q."id"
    GROUP BY p."user_id"
)

/* --------------------------------------------------------------------------*/
SELECT 
    u."id"            AS "user_id",
    u."display_name",
    v.total_views
FROM user_view_totals v
JOIN STACKOVERFLOW.STACKOVERFLOW."USERS" u
     ON v."user_id" = u."id"
ORDER BY v.total_views DESC NULLS LAST
LIMIT 10;