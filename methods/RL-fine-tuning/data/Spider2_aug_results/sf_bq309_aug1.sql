-- Task: Retrieve the top 10 longest questions on Stack Overflow, measured by the length of their body text. For each question, include the question ID, title, the length of the body text, and the reputation of the user who asked the question.
SELECT
    q."id" AS "Question_ID",
    q."title" AS "Question_Title",
    LENGTH(q."body") AS "Question_Length",
    u."reputation" AS "User_Reputation"
FROM
    STACKOVERFLOW.STACKOVERFLOW."POSTS_QUESTIONS" q
JOIN
    STACKOVERFLOW.STACKOVERFLOW."USERS" u ON q."owner_user_id" = u."id"
ORDER BY
    LENGTH(q."body") DESC NULLS LAST
LIMIT
    10;