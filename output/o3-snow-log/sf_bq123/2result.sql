WITH questions AS (
    SELECT
        "id"                                        AS question_id,
        "creation_date"                             AS q_create_us,
        DAYNAME(TO_TIMESTAMP("creation_date"/1000000))   AS day_name      -- name of weekday
    FROM STACKOVERFLOW.STACKOVERFLOW.POSTS_QUESTIONS
),
answers AS (                       -- earliest answer per question
    SELECT
        "parent_id"                               AS question_id,
        MIN("creation_date")                      AS a_first_us
    FROM STACKOVERFLOW.STACKOVERFLOW.POSTS_ANSWERS
    GROUP BY "parent_id"
),
joined AS (                         -- match questions to earliest answer
    SELECT
        q.day_name,
        CASE
            WHEN a.a_first_us IS NOT NULL
             AND a.a_first_us - q.q_create_us <= 3600000000    -- 3 600 s * 1 000 000 µs
            THEN 1 ELSE 0
        END                                           AS answered_within_hour
    FROM questions q
    LEFT JOIN answers a
           ON a.question_id = q.question_id
),
stats AS (                          -- percentage per weekday
    SELECT
        day_name,
        COUNT(*)                                             AS total_q,
        SUM(answered_within_hour)                            AS answered_q,
        ROUND( SUM(answered_within_hour)::FLOAT / COUNT(*), 4)  AS pct_within_hour
    FROM joined
    GROUP BY day_name
)
SELECT
    day_name,
    pct_within_hour
FROM stats
ORDER BY pct_within_hour DESC NULLS LAST
OFFSET 2 ROWS          -- skip 1st and 2nd → get 3rd highest
FETCH NEXT 1 ROWS ONLY;