WITH hn_comments AS (   -- gather all Hacker News comments
    SELECT "text", "time" FROM STACKOVERFLOW_PLUS.HACKERNEWS.FULL_201510
    UNION ALL
    SELECT "text", "time" FROM STACKOVERFLOW_PLUS.HACKERNEWS.FULL_PARTITIONED
    UNION ALL
    SELECT "text", "time" FROM STACKOVERFLOW_PLUS.HACKERNEWS.COMMENTSV2
    UNION ALL
    SELECT "text", "time" FROM STACKOVERFLOW_PLUS.HACKERNEWS.COMMENTS
    UNION ALL
    SELECT "text", "time" FROM STACKOVERFLOW_PLUS.HACKERNEWS.COMMENTS_CONVOLUTION
    UNION ALL
    SELECT "text", "time" FROM STACKOVERFLOW_PLUS.HACKERNEWS.FULL_PARTITION_EXTRA
),
extracted_ids AS (       -- pull Stack Overflow question IDs from each comment
    SELECT
        TO_NUMBER(
            REGEXP_SUBSTR(
                "text",
                'stackoverflow\\.com/[a-z]+/([0-9]+)',   -- capture the first numeric id
                1,        -- start position
                1,        -- first occurrence
                'c',      -- default parameters
                1         -- capture-group 1 is the id
            )
        ) AS question_id
    FROM hn_comments
    WHERE "time" >= 1388534400            -- on or after 2014-01-01
),
mention_counts AS (       -- count how many times each question was mentioned
    SELECT
        question_id,
        COUNT(*) AS mention_cnt
    FROM extracted_ids
    WHERE question_id IS NOT NULL
    GROUP BY question_id
),
tag_mentions AS (         -- explode each question’s tags and propagate mention counts
    SELECT
        tag_part.value::string AS tag,
        mc.mention_cnt
    FROM mention_counts mc
    JOIN STACKOVERFLOW_PLUS.STACKOVERFLOW.POSTS_QUESTIONS q
          ON q."id" = mc.question_id
    ,   LATERAL FLATTEN(SPLIT(q."tags", '|')) AS tag_part
)
SELECT
    tag,
    SUM(mention_cnt) AS total_mentions
FROM tag_mentions
GROUP BY tag
ORDER BY total_mentions DESC NULLS LAST
LIMIT 10;