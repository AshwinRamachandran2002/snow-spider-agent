SELECT
    MAX("answer_count") AS "max_answers"
FROM
    STACKOVERFLOW.STACKOVERFLOW.POSTS_QUESTIONS
WHERE
    LOWER("tags") LIKE '%python-2%'        -- Python 2–specific questions
    AND LOWER("tags") NOT LIKE '%python-3%'  -- exclude any Python 3 mentions
;