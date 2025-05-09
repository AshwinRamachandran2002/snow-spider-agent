/* Users’ contributions (comments, answers, questions) made
   from 2019-07-01 00:00:00 through 2019-12-31 23:59:59
   by users whose ids are in [16 712 208 … 18 712 208].
   Each row returns the contributor’s id together with the tags of
   the question to which that contribution ultimately belongs. */

WITH time_window AS (
    SELECT
        '2019-07-01'::TIMESTAMP AS dt_start,
        '2020-01-01'::TIMESTAMP AS dt_end
),

/* --- questions written by the users ----------------------------------- */
q_contrib AS (
    SELECT
        q."owner_user_id"                       AS user_id,
        q."tags"                                AS "tags"
    FROM   STACKOVERFLOW.STACKOVERFLOW."POSTS_QUESTIONS" q,
           time_window t
    WHERE  q."owner_user_id" BETWEEN 16712208 AND 18712208
      AND  TO_TIMESTAMP_LTZ(q."creation_date" / 1000000)
             BETWEEN t.dt_start AND t.dt_end - INTERVAL '1 MICROSECOND'
),

/* --- answers written by the users ------------------------------------- */
a_contrib AS (
    SELECT
        a."owner_user_id"                       AS user_id,
        pq."tags"                               AS "tags"
    FROM   STACKOVERFLOW.STACKOVERFLOW."POSTS_ANSWERS"   a
    JOIN   STACKOVERFLOW.STACKOVERFLOW."POSTS_QUESTIONS" pq
           ON pq."id" = a."parent_id",
           time_window t
    WHERE  a."owner_user_id" BETWEEN 16712208 AND 18712208
      AND  TO_TIMESTAMP_LTZ(a."creation_date" / 1000000)
             BETWEEN t.dt_start AND t.dt_end - INTERVAL '1 MICROSECOND'
),

/* --- comments written by the users on questions ----------------------- */
c_on_q AS (
    SELECT
        c."user_id"                             AS user_id,
        pq."tags"                               AS "tags"
    FROM   STACKOVERFLOW.STACKOVERFLOW."COMMENTS"         c
    JOIN   STACKOVERFLOW.STACKOVERFLOW."POSTS_QUESTIONS"  pq
           ON pq."id" = c."post_id",
           time_window t
    WHERE  c."user_id" BETWEEN 16712208 AND 18712208
      AND  TO_TIMESTAMP_LTZ(c."creation_date" / 1000000)
             BETWEEN t.dt_start AND t.dt_end - INTERVAL '1 MICROSECOND'
),

/* --- comments written by the users on answers ------------------------- */
c_on_a AS (
    SELECT
        c."user_id"                             AS user_id,
        pq."tags"                               AS "tags"
    FROM   STACKOVERFLOW.STACKOVERFLOW."COMMENTS"        c
    JOIN   STACKOVERFLOW.STACKOVERFLOW."POSTS_ANSWERS"   a
           ON a."id" = c."post_id"
    JOIN   STACKOVERFLOW.STACKOVERFLOW."POSTS_QUESTIONS" pq
           ON pq."id" = a."parent_id",
           time_window t
    WHERE  c."user_id" BETWEEN 16712208 AND 18712208
      AND  TO_TIMESTAMP_LTZ(c."creation_date" / 1000000)
             BETWEEN t.dt_start AND t.dt_end - INTERVAL '1 MICROSECOND'
)

/* -------------- aggregate all contribution rows ----------------------- */
SELECT  user_id,
        "tags"
FROM   (
        SELECT * FROM q_contrib
        UNION ALL
        SELECT * FROM a_contrib
        UNION ALL
        SELECT * FROM c_on_q
        UNION ALL
        SELECT * FROM c_on_a
       )
ORDER BY user_id,
         "tags" NULLS LAST;