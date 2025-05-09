WITH hn_comments AS (                         -- all Hacker News comments
    SELECT "text","time" FROM STACKOVERFLOW_PLUS.HACKERNEWS."COMMENTSV2"
    UNION ALL
    SELECT "text","time" FROM STACKOVERFLOW_PLUS.HACKERNEWS."COMMENTS"
    UNION ALL
    SELECT "text","time" FROM STACKOVERFLOW_PLUS.HACKERNEWS."FULL_201510"
    UNION ALL
    SELECT "text","time" FROM STACKOVERFLOW_PLUS.HACKERNEWS."FULL_PARTITIONED"
    UNION ALL
    SELECT "text","time" FROM STACKOVERFLOW_PLUS.HACKERNEWS."FULL_PARTITION_EXTRA"
    UNION ALL
    SELECT "text","time" FROM STACKOVERFLOW_PLUS.HACKERNEWS."COMMENTS_CONVOLUTION"
),                                                -- extract referenced SO-question ids
so_refs AS (
    SELECT
        TO_NUMBER(
            REGEXP_SUBSTR("text",
                          'stackoverflow\\.com/questions/([0-9]+)',
                          1,                       -- start position
                          1,                       -- 1st occurrence
                          'e',                     -- enable sub-expression
                          1)                       -- return 1st capture group
        ) AS question_id
    FROM hn_comments
    WHERE "time" >= 1388534400                    -- only comments from 2014-01-01 on
),
mentions AS (                                     -- how many times each question appears
    SELECT question_id, COUNT(*) AS mention_count
    FROM   so_refs
    WHERE  question_id IS NOT NULL
    GROUP  BY question_id
),
question_tags AS (                                -- split tag strings
    SELECT
        LOWER(TRIM(tag_elem.value::STRING))  AS tag,
        m.mention_count
    FROM mentions m
    JOIN STACKOVERFLOW_PLUS.STACKOVERFLOW."POSTS_QUESTIONS" q
         ON q."id" = m.question_id
    ,   LATERAL FLATTEN(input => SPLIT(q."tags",'|')) tag_elem
    WHERE q."tags" IS NOT NULL
),
tag_totals AS (                                   -- accumulate counts per tag
    SELECT tag,
           SUM(mention_count) AS total_mentions
    FROM   question_tags
    WHERE  tag IS NOT NULL
       AND tag <> ''
    GROUP  BY tag
)
SELECT tag,
       total_mentions
FROM   tag_totals
ORDER  BY total_mentions DESC NULLS LAST
LIMIT 10;