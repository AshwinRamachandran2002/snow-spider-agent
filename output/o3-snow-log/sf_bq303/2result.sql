WITH date_bounds AS (
    SELECT 
        1561939200000000 ::NUMBER AS start_us ,   -- 2019-07-01 00:00:00 UTC
        1577836800000000 ::NUMBER AS end_us       -- 2020-01-01 00:00:00 UTC (exclusive)
),

/* -------------------------------------------------------
   comments written directly on questions
------------------------------------------------------- */
comment_on_question AS (
    SELECT
        c."user_id"                       AS user_id ,
        q."tags"                          AS tags
    FROM STACKOVERFLOW.STACKOVERFLOW."COMMENTS"          AS c
    JOIN STACKOVERFLOW.STACKOVERFLOW."POSTS_QUESTIONS"   AS q
          ON q."id" = c."post_id"
    JOIN date_bounds d
          ON c."creation_date" >= d.start_us
         AND c."creation_date" <  d.end_us
    WHERE c."user_id" BETWEEN 16712208 AND 18712208
),

/* -------------------------------------------------------
   comments written on answers  →  fetch parent question’s tags
------------------------------------------------------- */
comment_on_answer AS (
    SELECT
        c."user_id"                       AS user_id ,
        q."tags"                          AS tags
    FROM STACKOVERFLOW.STACKOVERFLOW."COMMENTS"        AS c
    JOIN STACKOVERFLOW.STACKOVERFLOW."POSTS_ANSWERS"   AS a
          ON a."id" = c."post_id"
    JOIN STACKOVERFLOW.STACKOVERFLOW."POSTS_QUESTIONS" AS q
          ON q."id" = a."parent_id"
    JOIN date_bounds d
          ON c."creation_date" >= d.start_us
         AND c."creation_date" <  d.end_us
    WHERE c."user_id" BETWEEN 16712208 AND 18712208
),

/* -------------------------------------------------------
   answers posted  →  fetch parent question’s tags
------------------------------------------------------- */
answers AS (
    SELECT
        a."owner_user_id"                 AS user_id ,
        q."tags"                          AS tags
    FROM STACKOVERFLOW.STACKOVERFLOW."POSTS_ANSWERS"   AS a
    JOIN STACKOVERFLOW.STACKOVERFLOW."POSTS_QUESTIONS" AS q
          ON q."id" = a."parent_id"
    JOIN date_bounds d
          ON a."creation_date" >= d.start_us
         AND a."creation_date" <  d.end_us
    WHERE a."owner_user_id" BETWEEN 16712208 AND 18712208
),

/* -------------------------------------------------------
   questions authored
------------------------------------------------------- */
questions AS (
    SELECT
        q."owner_user_id"                 AS user_id ,
        q."tags"                          AS tags
    FROM STACKOVERFLOW.STACKOVERFLOW."POSTS_QUESTIONS" AS q
    JOIN date_bounds d
          ON q."creation_date" >= d.start_us
         AND q."creation_date" <  d.end_us
    WHERE q."owner_user_id" BETWEEN 16712208 AND 18712208
)

/* -------------------------------------------------------
   union everything
------------------------------------------------------- */
SELECT
    user_id ,
    tags
FROM (
        SELECT * FROM comment_on_question
        UNION ALL
        SELECT * FROM comment_on_answer
        UNION ALL
        SELECT * FROM answers
        UNION ALL
        SELECT * FROM questions
     )
;