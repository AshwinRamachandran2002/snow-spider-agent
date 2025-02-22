-- Task: For users with IDs between 16712208 and 18712208, retrieve their user ID and the tags of the relevant question for each comment they made on answers between July 1, 2019 and December 31, 2019.

SELECT cm.u_id, pq.tags
FROM (
    SELECT a.parent_id AS q_id, c.user_id AS u_id, c.creation_date AS creation_date
    FROM `bigquery-public-data.stackoverflow.comments` AS c
    INNER JOIN `bigquery-public-data.stackoverflow.posts_answers` AS a ON a.id = c.post_id
    WHERE c.user_id BETWEEN 16712208 AND 18712208
      AND DATE(c.creation_date) BETWEEN '2019-07-01' AND '2019-12-31'
) AS cm
INNER JOIN `bigquery-public-data.stackoverflow.posts_questions` AS pq ON pq.id = cm.q_id
ORDER BY cm.u_id, cm.creation_date;