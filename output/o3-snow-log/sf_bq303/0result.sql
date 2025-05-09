/* ---------------------------------------------------------
   Contributions (questions, answers, comments) made
   2019-07-01 00:00:00  ≤  creation_date  <  2020-01-01 00:00:00
   by users   16 712 208 – 18 712 208   (inclusive)
   Return: contributing user id  +  tags of the related question
   --------------------------------------------------------- */
WITH limits AS (
  SELECT
      1561939200000000::NUMBER AS start_us ,   -- 2019-07-01 00:00:00 UTC
      1577836800000000::NUMBER AS end_us   ,   -- 2020-01-01 00:00:00 UTC
      16712208                AS min_user ,
      18712208                AS max_user
)

/*  Collect all kinds of contributions and attach the parent-question tags  */
SELECT
       "user_id",
       "tags"
FROM (

  /* ---------- questions authored --------------------------------------- */
  SELECT
         q."owner_user_id"     AS "user_id",
         q."tags"
  FROM   "STACKOVERFLOW"."STACKOVERFLOW"."POSTS_QUESTIONS" q , limits l
  WHERE  q."creation_date" >= l.start_us
    AND  q."creation_date" <  l.end_us
    AND  q."owner_user_id" BETWEEN l.min_user AND l.max_user

  UNION ALL

  /* ---------- answers posted ------------------------------------------- */
  SELECT
         a."owner_user_id"     AS "user_id",
         q."tags"
  FROM   "STACKOVERFLOW"."STACKOVERFLOW"."POSTS_ANSWERS"   a
  JOIN   "STACKOVERFLOW"."STACKOVERFLOW"."POSTS_QUESTIONS" q
         ON q."id" = a."parent_id"
       , limits l
  WHERE  a."creation_date" >= l.start_us
    AND  a."creation_date" <  l.end_us
    AND  a."owner_user_id" BETWEEN l.min_user AND l.max_user

  UNION ALL

  /* ---------- comments made directly on questions ---------------------- */
  SELECT
         c."user_id",
         q."tags"
  FROM   "STACKOVERFLOW"."STACKOVERFLOW"."COMMENTS"        c
  JOIN   "STACKOVERFLOW"."STACKOVERFLOW"."POSTS_QUESTIONS" q
         ON q."id" = c."post_id"
       , limits l
  WHERE  c."creation_date" >= l.start_us
    AND  c."creation_date" <  l.end_us
    AND  c."user_id" BETWEEN l.min_user AND l.max_user

  UNION ALL

  /* ---------- comments made on answers --------------------------------- */
  SELECT
         c."user_id",
         q."tags"
  FROM   "STACKOVERFLOW"."STACKOVERFLOW"."COMMENTS"        c
  JOIN   "STACKOVERFLOW"."STACKOVERFLOW"."POSTS_ANSWERS"   a
         ON a."id" = c."post_id"
  JOIN   "STACKOVERFLOW"."STACKOVERFLOW"."POSTS_QUESTIONS" q
         ON q."id" = a."parent_id"
       , limits l
  WHERE  c."creation_date" >= l.start_us
    AND  c."creation_date" <  l.end_us
    AND  c."user_id" BETWEEN l.min_user AND l.max_user
) AS contributions
WHERE "tags" IS NOT NULL
ORDER BY "user_id", "tags";