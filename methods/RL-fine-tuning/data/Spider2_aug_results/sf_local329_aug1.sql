-- Task: For each session that visited '/regist/input' or '/regist/confirm' with status '', list the step number, path, and their earliest and latest timestamps.
SELECT
    l."session",
    m."step",
    m."path",
    MAX(l."stamp") AS "max_stamp",
    MIN(l."stamp") AS "min_stamp"
FROM
    (SELECT 
        1 AS "step", '/regist/input' AS "path"
     UNION ALL
     SELECT 
        2 AS "step", '/regist/confirm' AS "path") AS m
    JOIN LOG.LOG.FORM_LOG AS l
    ON m."path" = l."path"
WHERE 
    l."status" = ''
GROUP BY 
    l."session", m."step", m."path"
LIMIT 100;