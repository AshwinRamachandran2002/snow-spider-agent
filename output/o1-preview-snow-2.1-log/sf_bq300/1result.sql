SELECT MAX("answer_count") AS "highest_number_of_answers"
FROM STACKOVERFLOW.STACKOVERFLOW.POSTS_QUESTIONS
WHERE ("title" ILIKE '%python 2%' OR "body" ILIKE '%python 2%' OR "tags" ILIKE '%<python-2.x>%')
  AND "title" NOT ILIKE '%python 3%'
  AND "body" NOT ILIKE '%python 3%'
  AND "tags" NOT ILIKE '%<python-3.x>%';