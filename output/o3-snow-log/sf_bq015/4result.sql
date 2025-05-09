/* Top-10 Stack Overflow tags whose questions were referenced
   in Hacker News comments on or after 2014-01-01              */

WITH hn_comments AS (          -- comments that contain an SO question link
    SELECT "text"
    FROM (
          SELECT "text"
          FROM STACKOVERFLOW_PLUS.HACKERNEWS.FULL_201510
          WHERE "time" >= 1388534400
            AND "text" ILIKE '%stackoverflow.com/questions/%'
          UNION ALL
          SELECT "text"
          FROM STACKOVERFLOW_PLUS.HACKERNEWS.COMMENTSV2
          WHERE "time" >= 1388534400
            AND "text" ILIKE '%stackoverflow.com/questions/%'
          UNION ALL
          SELECT "text"
          FROM STACKOVERFLOW_PLUS.HACKERNEWS.FULL_PARTITION_EXTRA
          WHERE "time" >= 1388534400
            AND "text" ILIKE '%stackoverflow.com/questions/%'
          UNION ALL
          SELECT "text"
          FROM STACKOVERFLOW_PLUS.HACKERNEWS.COMMENTS
          WHERE "time" >= 1388534400
            AND "text" ILIKE '%stackoverflow.com/questions/%'
          UNION ALL
          SELECT "text"
          FROM STACKOVERFLOW_PLUS.HACKERNEWS.COMMENTS_CONVOLUTION
          WHERE "time" >= 1388534400
            AND "text" ILIKE '%stackoverflow.com/questions/%'
    )
),

nums AS (                       -- helper integers 1 … 20
    SELECT SEQ4() + 1 AS n
    FROM TABLE(GENERATOR(ROWCOUNT => 20))
),

extracted AS (                  -- extract every SO question-id from each comment
    SELECT
        CAST(
            REGEXP_SUBSTR(
                c."text",
                'stackoverflow\\.com/questions/([0-9]+)',
                1, n.n, 'e', 1
            ) AS NUMBER
        ) AS question_id
    FROM hn_comments c
    JOIN nums n
      ON REGEXP_SUBSTR(
             c."text",
             'stackoverflow\\.com/questions/([0-9]+)',
             1, n.n, 'e', 1
         ) IS NOT NULL
),

question_counts AS (            -- how many times was each question linked?
    SELECT question_id,
           COUNT(*) AS mention_count
    FROM extracted
    GROUP BY question_id
),

question_tags AS (              -- fetch tag strings for those questions
    SELECT qc.question_id,
           qc.mention_count,
           q."tags"
    FROM question_counts qc
    JOIN STACKOVERFLOW_PLUS.STACKOVERFLOW.POSTS_QUESTIONS q
      ON q."id" = qc.question_id
    WHERE q."tags" IS NOT NULL
),

tag_counts AS (                 -- explode tags and sum weighted mentions
    SELECT
        TRIM(t.VALUE::string)          AS tag,
        SUM(qt.mention_count)          AS total_mentions
    FROM question_tags qt,
         LATERAL SPLIT_TO_TABLE(qt."tags", '|') t
    GROUP BY tag
)

SELECT tag,
       total_mentions
FROM tag_counts
ORDER BY total_mentions DESC NULLS LAST
LIMIT 10;