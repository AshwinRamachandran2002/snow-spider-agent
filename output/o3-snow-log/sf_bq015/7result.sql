WITH comments_union AS (          -- combine every HN-comment table
    SELECT "time","text" FROM STACKOVERFLOW_PLUS.HACKERNEWS."COMMENTSV2"
    UNION ALL
    SELECT "time","text" FROM STACKOVERFLOW_PLUS.HACKERNEWS."COMMENTS"
    UNION ALL
    SELECT "time","text" FROM STACKOVERFLOW_PLUS.HACKERNEWS."COMMENTS_CONVOLUTION"
),

hn_references AS (                -- extract Stack Overflow question-ids mentioned ≥ 2014-01-01
    SELECT
        TO_NUMBER(
            REGEXP_SUBSTR(
                "text",
                'stackoverflow\\.com/(questions|q)/([0-9]+)',   -- capture digits after /questions/ or /q/
                1,        -- start position
                1,        -- first match
                'e',      -- enable sub-expressions
                2         -- return 2nd capture group -> the numeric id
            )
        )                                   AS question_id
    FROM comments_union
    WHERE "time" >= 1388534400              -- 2014-01-01 00:00:00 UTC
),

referenced_questions AS (          -- count how many times each question id appeared
    SELECT
        question_id,
        COUNT(*)                    AS mention_count
    FROM hn_references
    WHERE question_id IS NOT NULL
    GROUP BY question_id
),

question_tags AS (                 -- bring in the tag strings for those questions
    SELECT
        rq.question_id,
        rq.mention_count,
        q."tags"
    FROM referenced_questions rq
    JOIN STACKOVERFLOW_PLUS.STACKOVERFLOW."POSTS_QUESTIONS" q
      ON q."id" = rq.question_id
    WHERE q."tags" IS NOT NULL
),

tag_counts AS (                    -- split tag strings and aggregate counts
    SELECT
        f.VALUE::STRING            AS tag,
        SUM(mention_count)         AS total_mentions
    FROM question_tags,
         LATERAL FLATTEN( INPUT => SPLIT("tags", '|') ) f
    GROUP BY f.VALUE
)

SELECT
    tag,
    total_mentions
FROM tag_counts
ORDER BY total_mentions DESC NULLS LAST
LIMIT 10;