-- Task: Retrieve details of answers that are the accepted answers to Stack Overflow questions posted in January 2016, where the questions have tags including 'javascript' and at least one of 'xss', 'cross-site', 'exploit', or 'cybersecurity'. The accepted answers must also have been posted in January 2016.

-- For each such accepted answer, include:
-- - The answer's ID
-- - The answerer's reputation (from the users table)
-- - The answer's score
-- - The answer's comment count

-- Along with the associated question's:
-- - Tags
-- - Score
-- - Answer count
-- - Asker's reputation (from the users table)
-- - View count
-- - Comment count

SELECT
    answer.id AS a_id,
    (SELECT users.reputation FROM `bigquery-public-data.stackoverflow.users` users
        WHERE users.id = answer.owner_user_id) AS a_user_reputation,
    answer.score AS a_score,
    answer.comment_count AS answer_comment_count,
    questions.tags AS q_tags,
    questions.score AS q_score,
    questions.answer_count AS answer_count,
    (SELECT users.reputation FROM `bigquery-public-data.stackoverflow.users` users
        WHERE users.id = questions.owner_user_id) AS q_user_reputation,
    questions.view_count AS q_view_count,
    questions.comment_count AS q_comment_count
FROM
    `bigquery-public-data.stackoverflow.posts_answers` AS answer
LEFT JOIN
    `bigquery-public-data.stackoverflow.posts_questions` AS questions
    ON answer.parent_id = questions.id
WHERE
    answer.id = questions.accepted_answer_id
    AND (
        questions.tags LIKE '%javascript%' AND (
            questions.tags LIKE '%xss%' OR
            questions.tags LIKE '%cross-site%' OR
            questions.tags LIKE '%exploit%' OR
            questions.tags LIKE '%cybersecurity%'
        )
    )
    AND DATE(questions.creation_date) BETWEEN '2016-01-01' AND '2016-01-31'
    AND DATE(answer.creation_date) BETWEEN '2016-01-01' AND '2016-01-31'