SELECT MAX("answer_count") AS "max_answers"
FROM   STACKOVERFLOW.STACKOVERFLOW.POSTS_QUESTIONS
WHERE  "tags" ILIKE '%python-2%'          -- only Python 2-specific questions
  AND  "tags" NOT ILIKE '%python-3%'      -- exclude any question mentioning Python 3
  AND  "answer_count" IS NOT NULL;        -- ensure the value is present