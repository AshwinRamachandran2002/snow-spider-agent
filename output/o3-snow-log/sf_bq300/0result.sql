SELECT
    MAX("answer_count") AS "highest_answer_count_python2_question"
FROM
    STACKOVERFLOW.STACKOVERFLOW.POSTS_QUESTIONS
WHERE
      ("tags" ILIKE '%python-2%' OR "tags" ILIKE '%python2%')   -- Python 2–specific
  AND "tags" NOT ILIKE '%python-3%'                             -- exclude Python 3
  AND "tags" NOT ILIKE '%python3%';