WITH q AS (     /* questions with body length calculated */
    SELECT  q."id",
            q."body",
            q."view_count",
            q."accepted_answer_id",
            q."owner_user_id",
            LENGTH(q."body")      AS body_len
    FROM    STACKOVERFLOW.STACKOVERFLOW."POSTS_QUESTIONS" q
),
a AS (           /* every answer’s score with its parent question */
    SELECT  a."parent_id",
            a."score"
    FROM    STACKOVERFLOW.STACKOVERFLOW."POSTS_ANSWERS" a
),
good_answer_questions AS (  /* questions (no accepted answer) having ≥1 answer with score/view > .01 */
    SELECT DISTINCT q."id"
    FROM   q
    JOIN   a
           ON a."parent_id" = q."id"
    WHERE  q."accepted_answer_id" IS NULL
      AND  q."view_count" IS NOT NULL
      AND  q."view_count" > 0
      AND  a."score" / q."view_count" > 0.01
),
qualified_questions AS (   /* union of questions that meet either rule */
    SELECT q.*
    FROM   q
    LEFT JOIN good_answer_questions g
           ON g."id" = q."id"
    WHERE  q."accepted_answer_id" IS NOT NULL
        OR g."id" IS NOT NULL
),
user_core AS (   /* user reputation & net votes */
    SELECT  u."id"                        AS user_id,
            u."reputation",
            u."up_votes" - u."down_votes" AS "net_votes"
    FROM    STACKOVERFLOW.STACKOVERFLOW."USERS" u
),
badge_totals AS ( /* badge count per user */
    SELECT  b."user_id",
            COUNT(*)                      AS "badge_count"
    FROM    STACKOVERFLOW.STACKOVERFLOW."BADGES" b
    GROUP BY b."user_id"
)
SELECT  q."id"                           AS question_id,
        uc."reputation",
        uc."net_votes",
        COALESCE(bt."badge_count", 0)    AS badge_count
FROM    qualified_questions q
LEFT JOIN user_core   uc ON uc.user_id   = q."owner_user_id"
LEFT JOIN badge_totals bt ON bt."user_id"= q."owner_user_id"
ORDER BY q.body_len DESC NULLS LAST
LIMIT 10;