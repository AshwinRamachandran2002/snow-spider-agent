SELECT 
    MAX("answer_count") AS "max_answers_python2_question"
FROM 
    STACKOVERFLOW.STACKOVERFLOW.POSTS_QUESTIONS
WHERE 
      ( "tags" LIKE '%python-2%'  OR "tags" LIKE '%python2%' )
  AND "tags" NOT LIKE '%python-3%'
  AND "tags" NOT LIKE '%python3%';