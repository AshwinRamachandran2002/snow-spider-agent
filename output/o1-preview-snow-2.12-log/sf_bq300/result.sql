SELECT MAX("answer_count") AS highest_number_of_answers
FROM STACKOVERFLOW.STACKOVERFLOW.POSTS_QUESTIONS
WHERE (
    ('|' || "tags" || '|') ILIKE '%|python-2%|%'
    OR "title" ILIKE '%Python 2%'
    OR "title" ILIKE '%Python2%'
    OR "body" ILIKE '%Python 2%'
    OR "body" ILIKE '%Python2%'
)
AND NOT (
    ('|' || "tags" || '|') ILIKE '%|python-3%|%'
    OR ('|' || "tags" || '|') ILIKE '%|python3%|%'
    OR "title" ILIKE '%Python 3%'
    OR "title" ILIKE '%Python3%'
    OR "body" ILIKE '%Python 3%'
    OR "body" ILIKE '%Python3%'
);