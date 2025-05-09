WITH questions2021 AS (
    SELECT
        q."id",
        q."creation_date"                              AS q_cd_micro,
        DAYNAME(TO_TIMESTAMP_NTZ(q."creation_date"/1e6))         AS weekday_name,
        DAYOFWEEK(TO_TIMESTAMP_NTZ(q."creation_date"/1e6))       AS weekday_num
    FROM STACKOVERFLOW.STACKOVERFLOW."POSTS_QUESTIONS" q
    WHERE TO_DATE(TO_TIMESTAMP_NTZ(q."creation_date"/1e6))
          BETWEEN '2021-01-01' AND '2021-12-31'
),
answered_within_1h AS (
    SELECT DISTINCT q."id"
    FROM questions2021 q
    JOIN STACKOVERFLOW.STACKOVERFLOW."POSTS_ANSWERS" a
         ON a."parent_id" = q."id"
        AND a."creation_date" BETWEEN q.q_cd_micro
                                  AND q.q_cd_micro + 3600000000   -- 3 600 s in µs
)
SELECT
    q.weekday_name                                       AS "weekday",
    COUNT(*)                                             AS "total_questions",
    SUM(CASE WHEN aw."id" IS NOT NULL THEN 1 ELSE 0 END) AS "answered_within_1h",
    ROUND(
        SUM(CASE WHEN aw."id" IS NOT NULL THEN 1 ELSE 0 END)::FLOAT
        / COUNT(*) * 100, 
        4
    )                                                    AS "percent_answered_within_1h"
FROM questions2021 q
LEFT JOIN answered_within_1h aw
       ON aw."id" = q."id"
GROUP BY q.weekday_name, q.weekday_num
ORDER BY q.weekday_num;