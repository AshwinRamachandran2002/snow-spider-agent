WITH 

/* ---------------------------------------------------------------------------
   Every question together with its tags – used for all later look-ups
--------------------------------------------------------------------------- */
"QUESTION_TAGS" AS (   
    SELECT  "id"          AS "question_id",
            "tags"
    FROM    STACKOVERFLOW.STACKOVERFLOW."POSTS_QUESTIONS"
),

/* ---------------------------------------------------------------------------
   All questions written by the target users in the requested period
--------------------------------------------------------------------------- */
"MY_QUESTIONS" AS (
    SELECT  "owner_user_id"           AS "user_id",
            "id"                      AS "question_id",
            "tags"
    FROM    STACKOVERFLOW.STACKOVERFLOW."POSTS_QUESTIONS"
    WHERE   "owner_user_id" BETWEEN 16712208 AND 18712208
      AND   TO_TIMESTAMP("creation_date", 6) >= '2019-07-01'
      AND   TO_TIMESTAMP("creation_date", 6) <  '2020-01-01'
),

/* ---------------------------------------------------------------------------
   All answers written by the target users in the requested period
--------------------------------------------------------------------------- */
"MY_ANSWERS" AS (
    SELECT  "id"            AS "answer_id",
            "parent_id"     AS "question_id",
            "owner_user_id" AS "user_id"
    FROM    STACKOVERFLOW.STACKOVERFLOW."POSTS_ANSWERS"
    WHERE   "owner_user_id" BETWEEN 16712208 AND 18712208
      AND   TO_TIMESTAMP("creation_date", 6) >= '2019-07-01'
      AND   TO_TIMESTAMP("creation_date", 6) <  '2020-01-01'
),

/* ---------------------------------------------------------------------------
   All comments (on questions *and* answers) written by the target users
--------------------------------------------------------------------------- */
"MY_COMMENTS" AS (
    SELECT  "id"        AS "comment_id",
            "post_id",           -- can be a question or an answer
            "user_id"
    FROM    STACKOVERFLOW.STACKOVERFLOW."COMMENTS"
    WHERE   "user_id" BETWEEN 16712208 AND 18712208
      AND   TO_TIMESTAMP("creation_date", 6) >= '2019-07-01'
      AND   TO_TIMESTAMP("creation_date", 6) <  '2020-01-01'
),

/* ---------------------------------------------------------------------------
   Comments written directly on questions
--------------------------------------------------------------------------- */
"COMMENTS_ON_QUESTIONS" AS (
    SELECT  c."user_id",
            q."tags"
    FROM    "MY_COMMENTS"              c
    JOIN    STACKOVERFLOW.STACKOVERFLOW."POSTS_QUESTIONS" q
           ON q."id" = c."post_id"
),

/* ---------------------------------------------------------------------------
   Comments written on answers (need one more hop to the parent question)
--------------------------------------------------------------------------- */
"COMMENTS_ON_ANSWERS" AS (
    SELECT  c."user_id",
            qt."tags"
    FROM    "MY_COMMENTS"                           c
    JOIN    STACKOVERFLOW.STACKOVERFLOW."POSTS_ANSWERS"  a
           ON a."id" = c."post_id"
    JOIN    "QUESTION_TAGS"                         qt
           ON qt."question_id" = a."parent_id"
),

/* ---------------------------------------------------------------------------
   Answers – linked to their parent question’s tags
--------------------------------------------------------------------------- */
"ANSWER_CONTRIBS" AS (
    SELECT  a."user_id",
            qt."tags"
    FROM    "MY_ANSWERS"    a
    JOIN    "QUESTION_TAGS" qt
           ON qt."question_id" = a."question_id"
)

/* ---------------------------------------------------------------------------
   Final union of every kind of contribution
--------------------------------------------------------------------------- */
SELECT  "user_id",
        "tags"
FROM   (
        SELECT "user_id", "tags" FROM "MY_QUESTIONS"
        UNION ALL
        SELECT "user_id", "tags" FROM "ANSWER_CONTRIBS"
        UNION ALL
        SELECT "user_id", "tags" FROM "COMMENTS_ON_QUESTIONS"
        UNION ALL
        SELECT "user_id", "tags" FROM "COMMENTS_ON_ANSWERS"
       );