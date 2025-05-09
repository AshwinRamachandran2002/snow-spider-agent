WITH questions AS (
    SELECT
        "id"                                                    AS question_id,
        "creation_date"                                         AS q_cd_micro,
        TO_TIMESTAMP("creation_date" / 1000000.0)               AS q_ts
    FROM STACKOVERFLOW.STACKOVERFLOW."POSTS_QUESTIONS"
),
answers AS (
    SELECT
        "parent_id"                                             AS question_id,
        MIN("creation_date")                                    AS a_cd_micro
    FROM STACKOVERFLOW.STACKOVERFLOW."POSTS_ANSWERS"
    GROUP BY "parent_id"
),
qa AS (
    SELECT
        TO_CHAR(q.q_ts, 'DY')                                   AS day_of_week,
        CASE
            WHEN a.a_cd_micro IS NOT NULL
                 AND (a.a_cd_micro - q.q_cd_micro) <= 3600000000
            THEN 1 ELSE 0
        END                                                     AS answered_within_hour
    FROM questions q
    LEFT JOIN answers a
           ON q.question_id = a.question_id
),
day_stats AS (
    SELECT
        day_of_week,
        ROUND(100.0 * SUM(answered_within_hour) / COUNT(*), 4)  AS pct_within_hour
    FROM qa
    GROUP BY day_of_week
),
ordered AS (
    SELECT
        day_of_week,
        pct_within_hour,
        ROW_NUMBER() OVER (ORDER BY pct_within_hour DESC NULLS LAST) AS rn
    FROM day_stats
)
SELECT
    day_of_week,
    pct_within_hour
FROM ordered
WHERE rn = 3;