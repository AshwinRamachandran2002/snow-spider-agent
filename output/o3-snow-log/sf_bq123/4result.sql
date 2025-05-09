WITH "QUESTIONS" AS (      -- every question with its Unix-epoch time in µs
    SELECT 
        "id"                                     AS "question_id",
        "creation_date"                          AS "q_time_us",
        TO_TIMESTAMP_LTZ("creation_date"/1000000)   AS "q_ts"
    FROM STACKOVERFLOW.STACKOVERFLOW."POSTS_QUESTIONS"
), 

"EARLIEST_ANSWERS" AS (    -- first answer (if any) per question
    SELECT 
        "parent_id"                              AS "question_id",
        MIN("creation_date")                     AS "a_time_us"
    FROM STACKOVERFLOW.STACKOVERFLOW."POSTS_ANSWERS"
    GROUP BY "parent_id"
), 

"QUESTION_LEVEL" AS (      -- flag whether each question got an answer within an hour
    SELECT
        TO_CHAR(q."q_ts", 'DY')                  AS "day_of_week",         -- MON, TUE, …
        CASE 
            WHEN a."a_time_us" IS NOT NULL 
                 AND (a."a_time_us" - q."q_time_us") <= 3600*1000000       -- 1 hour in µs
            THEN 1 ELSE 0 
        END                                       AS "within_hour"
    FROM "QUESTIONS" q
    LEFT JOIN "EARLIEST_ANSWERS" a
           ON q."question_id" = a."question_id"
), 

"DAY_STATS" AS (            -- percentage of questions answered within an hour
    SELECT
        "day_of_week",
        SUM("within_hour")                     AS "quick_cnt",
        COUNT(*)                               AS "total_cnt",
        SUM("within_hour") * 100.0 / COUNT(*)  AS "pct_within_hour"
    FROM "QUESTION_LEVEL"
    GROUP BY "day_of_week"
), 

"RANKED" AS (               -- rank days by that percentage
    SELECT
        "day_of_week",
        "pct_within_hour",
        DENSE_RANK() OVER (ORDER BY "pct_within_hour" DESC) AS "rnk"
    FROM "DAY_STATS"
)

SELECT 
    "day_of_week",
    "pct_within_hour"
FROM "RANKED"
WHERE "rnk" = 3;            -- third-highest percentage