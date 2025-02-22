-- Task: What is the highest number of answers received for a question tagged with 'python-2'?
SELECT MAX("answer_count") AS highest_number_of_answers
FROM STACKOVERFLOW.STACKOVERFLOW.POSTS_QUESTIONS
WHERE ('|' || "tags" || '|') ILIKE '%|python-2|%';