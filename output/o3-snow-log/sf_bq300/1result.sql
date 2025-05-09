SELECT
    MAX("answer_count") AS "max_answers_for_python2_question"
FROM
    STACKOVERFLOW.STACKOVERFLOW.POSTS_QUESTIONS
WHERE
    "answer_count" IS NOT NULL
    -- must be about Python 2 …
    AND LOWER("tags") LIKE '%python-2%'
    -- … and must NOT mention Python 3
    AND LOWER("tags") NOT LIKE '%python-3%';