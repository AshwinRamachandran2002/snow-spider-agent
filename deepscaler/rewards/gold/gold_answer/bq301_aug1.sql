-- Task: Retrieve the IDs and reputations of answerers of accepted answers to Stack Overflow questions that have tags including "javascript" and at least one of "xss", "cross-site", "exploit", or "cybersecurity". For each accepted answer, include the answer's ID and the answerer's reputation.
SELECT
    answer.id AS a_id,
    (SELECT users.reputation FROM `bigquery-public-data.stackoverflow.users` users
        WHERE users.id = answer.owner_user_id) AS a_user_reputation
FROM
   `bigquery-public-data.stackoverflow.posts_answers` AS answer 
LEFT JOIN
   `bigquery-public-data.stackoverflow.posts_questions` AS questions
      ON answer.parent_id = questions.id
WHERE
    answer.id = questions.accepted_answer_id
    AND (
        questions.tags LIKE '%javascript%' AND
        (questions.tags LIKE '%xss%' OR
         questions.tags LIKE '%cross-site%' OR
         questions.tags LIKE '%exploit%' OR
         questions.tags LIKE '%cybersecurity%')
    )