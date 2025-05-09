WITH questions_filtered AS (
    SELECT
        q.id,
        q.title,
        q.body,
        q.owner_user_id,
        LENGTH(q.body) AS body_length
    FROM `bigquery-public-data.stackoverflow.posts_questions` AS q
    WHERE
        -- keep questions that either have an accepted answer …
        q.accepted_answer_id IS NOT NULL

        -- … or have at least one answer whose (answer‑score / question‑views) > 0.01
        OR (
            q.accepted_answer_id IS NULL
            AND q.view_count IS NOT NULL
            AND q.view_count > 0
            AND EXISTS (
                SELECT 1
                FROM `bigquery-public-data.stackoverflow.posts_answers` AS a
                WHERE a.parent_id = q.id
                  AND (a.score / CAST(q.view_count AS FLOAT64)) > 0.01
            )
        )
),

user_badges AS (
    SELECT
        user_id,
        COUNT(*) AS badge_count
    FROM `bigquery-public-data.stackoverflow.badges`
    GROUP BY user_id
)

SELECT
    q.id               AS question_id,
    q.body_length,
    u.reputation,
    (u.up_votes - u.down_votes) AS net_votes,
    COALESCE(b.badge_count, 0)  AS badge_count
FROM questions_filtered AS q
LEFT JOIN `bigquery-public-data.stackoverflow.users`   AS u
       ON u.id = q.owner_user_id
LEFT JOIN user_badges AS b
       ON b.user_id = q.owner_user_id
ORDER BY
    q.body_length DESC,
    q.id
LIMIT 10;