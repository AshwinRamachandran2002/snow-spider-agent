/*  Top-10 users by total view-count of questions they are associated with  */
WITH "ASSOCIATIONS" AS (

    /* 1. the owner of each question */
    SELECT  q."id"                     AS "question_id",
            q."owner_user_id"          AS "user_id"
    FROM    STACKOVERFLOW.STACKOVERFLOW."POSTS_QUESTIONS" q

    UNION

    /* 2. the author of each accepted answer */
    SELECT  q."id"                     AS "question_id",
            a."owner_user_id"          AS "user_id"
    FROM    STACKOVERFLOW.STACKOVERFLOW."POSTS_QUESTIONS" q
    JOIN    STACKOVERFLOW.STACKOVERFLOW."POSTS_ANSWERS"   a
           ON q."accepted_answer_id" = a."id"

    UNION

    /* 3. every answer with score > 5 */
    SELECT  a."parent_id"              AS "question_id",
            a."owner_user_id"          AS "user_id"
    FROM    STACKOVERFLOW.STACKOVERFLOW."POSTS_ANSWERS" a
    WHERE   a."score" > 5

    UNION

    /* 4. answers whose score is ≥ 20 % of the question’s total answer score (and > 0) */
    SELECT  a."parent_id"              AS "question_id",
            a."owner_user_id"          AS "user_id"
    FROM    STACKOVERFLOW.STACKOVERFLOW."POSTS_ANSWERS" a
    JOIN   ( SELECT  "parent_id",
                    SUM("score") AS "total_score"
             FROM   STACKOVERFLOW.STACKOVERFLOW."POSTS_ANSWERS"
             GROUP  BY "parent_id"
           ) t
      ON    a."parent_id" = t."parent_id"
    WHERE   a."score" > 0
      AND   a."score" >= 0.20 * t."total_score"

    UNION

    /* 5. the three highest-scoring answers for every question */
    SELECT  ranked."parent_id"         AS "question_id",
            ranked."owner_user_id"     AS "user_id"
    FROM   ( SELECT  a."parent_id",
                     a."owner_user_id",
                     ROW_NUMBER() OVER (PARTITION BY a."parent_id"
                                         ORDER BY a."score" DESC) AS rn
             FROM    STACKOVERFLOW.STACKOVERFLOW."POSTS_ANSWERS" a
           ) ranked
    WHERE   ranked.rn <= 3
)

SELECT      assoc."user_id",
            SUM( COALESCE(q."view_count",0) ) AS "combined_views"
FROM        "ASSOCIATIONS"              assoc
JOIN        STACKOVERFLOW.STACKOVERFLOW."POSTS_QUESTIONS" q
       ON   assoc."question_id" = q."id"
GROUP BY    assoc."user_id"
ORDER BY    "combined_views" DESC NULLS LAST
LIMIT 10;