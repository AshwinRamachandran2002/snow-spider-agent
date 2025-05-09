SELECT MAX("answer_count") AS "highest_answer_count"
FROM STACKOVERFLOW.STACKOVERFLOW.POSTS_QUESTIONS
WHERE "tags" IS NOT NULL
      -- tag list is pipe-delimited, match any tag that starts with python-2
  AND REGEXP_LIKE("tags", '(^|\|)python-2[^\|]*')
      -- exclude every question that has any python-3* tag
  AND NOT REGEXP_LIKE("tags", '(^|\|)python-3[^\|]*');