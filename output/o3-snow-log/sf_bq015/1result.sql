WITH comments_union AS (   -- all Hacker News comments
    SELECT "id","text","time"
    FROM STACKOVERFLOW_PLUS.HACKERNEWS.COMMENTSV2
    
    UNION ALL
    SELECT "id","text","time"
    FROM STACKOVERFLOW_PLUS.HACKERNEWS.COMMENTS
    
    UNION ALL
    SELECT "id","text","time"
    FROM STACKOVERFLOW_PLUS.HACKERNEWS.COMMENTS_CONVOLUTION
    
    UNION ALL
    SELECT "id","text","time"
    FROM STACKOVERFLOW_PLUS.HACKERNEWS.FULL_201510
    WHERE "type" = 'comment'
    
    UNION ALL
    SELECT "id","text","time"
    FROM STACKOVERFLOW_PLUS.HACKERNEWS.FULL_PARTITIONED
    WHERE "type" = 'comment'
),
mentions AS (              -- comments that mention SO questions (2014-01-01+)
    SELECT
        CAST(
            REGEXP_SUBSTR("text",
                           'stackoverflow\\.com/questions/(\\d+)',
                           1,                       -- start position
                           1,                       -- first occurrence
                           'e',                     -- enable sub-expressions
                           1)                       -- return 1st captured group
            AS NUMBER)      AS question_id
    FROM comments_union
    WHERE "time" >= 1388534400                             -- 2014-01-01
      AND REGEXP_SUBSTR("text",
                        'stackoverflow\\.com/questions/(\\d+)',
                        1,1,'e',1) IS NOT NULL
),
question_tags AS (        -- join to Stack Overflow questions and keep tags
    SELECT
        m.question_id,
        pq."tags"
    FROM mentions m
    JOIN STACKOVERFLOW_PLUS.STACKOVERFLOW.POSTS_QUESTIONS pq
          ON pq."id" = m.question_id
    WHERE pq."tags" IS NOT NULL
),
tag_counts AS (           -- split tags and count mentions
    SELECT
        LOWER(TRIM(f.value::string))          AS tag,
        COUNT(*)                              AS mention_count
    FROM question_tags qt,
         LATERAL FLATTEN(input => SPLIT(qt."tags", '|')) f
    WHERE TRIM(f.value::string) <> ''
    GROUP BY tag
)
SELECT tag,
       mention_count
FROM tag_counts
ORDER BY mention_count DESC NULLS LAST
LIMIT 10;