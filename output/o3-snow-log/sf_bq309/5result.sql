WITH "badges_per_user" AS (
    SELECT
        "user_id",
        COUNT(*) AS "badge_count"
    FROM STACKOVERFLOW.STACKOVERFLOW.BADGES
    GROUP BY "user_id"
),
"answers_max" AS (
    SELECT
        "parent_id",
        MAX("score") AS "max_score"
    FROM STACKOVERFLOW.STACKOVERFLOW.POSTS_ANSWERS
    GROUP BY "parent_id"
),
"qualified_questions" AS (
    SELECT
        q."id"            AS "question_id",
        q."owner_user_id" AS "asker_id",
        LENGTH(q."body")  AS "body_len"
    FROM STACKOVERFLOW.STACKOVERFLOW.POSTS_QUESTIONS q
    LEFT JOIN "answers_max" a
           ON a."parent_id" = q."id"
    WHERE  q."accepted_answer_id" IS NOT NULL
       OR (
              q."accepted_answer_id" IS NULL
          AND a."max_score" IS NOT NULL
          AND q."view_count" > 0
          AND (a."max_score" / q."view_count") > 0.01
       )
)
SELECT
    qq."question_id",
    qq."body_len",
    u."reputation"                       AS "user_reputation",
    (u."up_votes" - u."down_votes")      AS "net_votes",
    COALESCE(b."badge_count", 0)         AS "badge_count"
FROM "qualified_questions" qq
JOIN STACKOVERFLOW.STACKOVERFLOW.USERS u
     ON u."id" = qq."asker_id"
LEFT JOIN "badges_per_user" b
     ON b."user_id" = qq."asker_id"
ORDER BY qq."body_len" DESC NULLS LAST
FETCH 10;