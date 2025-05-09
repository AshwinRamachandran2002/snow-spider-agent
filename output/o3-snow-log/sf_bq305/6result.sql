/* -------------------------------------------------------------------------
   Top-10 users by combined view-counts of the questions they are associated
   with, evaluated in a single pass over the answers table to minimise work.
-----------------------------------------------------------------------------*/
WITH
/* pull required columns from questions once --------------------------------*/
questions AS (
    SELECT
        "id",
        "owner_user_id",
        "view_count",
        "accepted_answer_id"
    FROM STACKOVERFLOW.STACKOVERFLOW."POSTS_QUESTIONS"
),

/* rule-1 : question owners --------------------------------------------------*/
owners AS (
    SELECT
        "id"           AS question_id,
        "owner_user_id" AS user_id
    FROM questions
    WHERE "owner_user_id" IS NOT NULL
),

/* enrich every answer with total score of its question and rank ------------*/
answers_enriched AS (
    SELECT
        a."id",
        a."parent_id",
        a."owner_user_id",
        a."score",
        SUM(a."score") OVER (PARTITION BY a."parent_id")                              AS tot_score,
        ROW_NUMBER()  OVER (PARTITION BY a."parent_id" ORDER BY a."score" DESC, a."id") AS rn
    FROM STACKOVERFLOW.STACKOVERFLOW."POSTS_ANSWERS" a
    WHERE a."owner_user_id" IS NOT NULL
),

/* rules 2-5 gathered from the same answer scan -----------------------------*/
assoc_from_answers AS (
    SELECT DISTINCT
        /* for accepted answers use the real question id, otherwise parent_id */
        COALESCE(q."id", ae."parent_id") AS question_id,
        ae."owner_user_id"               AS user_id
    FROM answers_enriched ae
    LEFT JOIN questions q
           ON q."accepted_answer_id" = ae."id"
    WHERE
          /* rule-2 : accepted answer owner */
          q."accepted_answer_id" IS NOT NULL
       OR /* rule-3 : answer score > 5 */
          ae."score" > 5
       OR /* rule-4 : answer > 0 and > 20 % of total score */
          (ae."score" > 0 AND ae."score" > 0.20 * ae.tot_score)
       OR /* rule-5 : one of the top-3 scoring answers */
          ae.rn <= 3
),

/* union all associations and deduplicate ----------------------------------*/
assoc AS (
    SELECT * FROM owners
    UNION
    SELECT * FROM assoc_from_answers
),

/* accumulate view-counts per user -----------------------------------------*/
user_views AS (
    SELECT
        assoc.user_id,
        SUM(COALESCE(q."view_count", 0)) AS total_views
    FROM assoc
    JOIN questions q
      ON q."id" = assoc.question_id
    GROUP BY assoc.user_id
)

/* final top-10 list --------------------------------------------------------*/
SELECT
    uv.user_id,
    u."display_name",
    uv.total_views
FROM user_views uv
LEFT JOIN STACKOVERFLOW.STACKOVERFLOW."USERS" u
       ON u."id" = uv.user_id
ORDER BY uv.total_views DESC
LIMIT 10;