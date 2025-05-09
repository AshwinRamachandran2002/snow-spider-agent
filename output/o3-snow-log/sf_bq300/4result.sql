SELECT 
    MAX("answer_count") AS "max_answers"
FROM 
    STACKOVERFLOW.STACKOVERFLOW.POSTS_QUESTIONS
WHERE 
    "tags" ILIKE '%python-2%'      -- question specifically about Python 2
    AND "tags" NOT ILIKE '%python-3%'  -- exclude any mention of Python 3
;