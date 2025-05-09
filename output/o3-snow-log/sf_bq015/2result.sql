WITH comments_union AS (                         -- gather all Hacker News comments
    SELECT "text","time"
      FROM STACKOVERFLOW_PLUS.HACKERNEWS.COMMENTSV2
    UNION ALL
    SELECT "text","time"
      FROM STACKOVERFLOW_PLUS.HACKERNEWS.COMMENTS
    UNION ALL
    SELECT "text","time"
      FROM STACKOVERFLOW_PLUS.HACKERNEWS.COMMENTS_CONVOLUTION
    UNION ALL
    SELECT "text","time"
      FROM STACKOVERFLOW_PLUS.HACKERNEWS.FULL_201510
     WHERE "type" = 'comment'
    UNION ALL
    SELECT "text","time"
      FROM STACKOVERFLOW_PLUS.HACKERNEWS.FULL_PARTITION_EXTRA
     WHERE "type" = 'comment'
    UNION ALL
    SELECT "text","time"
      FROM STACKOVERFLOW_PLUS.HACKERNEWS.FULL_PARTITIONED
     WHERE "type" = 'comment'
),
so_links AS (                                     -- extract Stack Overflow question-ids
    SELECT TO_NUMBER(
               REGEXP_SUBSTR(
                   "text",
                   'stackoverflow\\.com/(questions|q)/([0-9]+)',   -- capture id (group 2)
                   1, 1, 'e', 2                                    -- return group 2
               )
           ) AS question_id
      FROM comments_union
     WHERE "time" >= 1388534400                  -- from 2014-01-01 (unix epoch)
),
question_mentions AS (                            -- count mentions per question
    SELECT question_id,
           COUNT(*) AS mention_cnt
      FROM so_links
     WHERE question_id IS NOT NULL
     GROUP BY question_id
),
question_tags AS (                                -- join with Stack Overflow questions
    SELECT qm.question_id,
           qm.mention_cnt,
           pq."tags"
      FROM question_mentions qm
      JOIN STACKOVERFLOW_PLUS.STACKOVERFLOW.POSTS_QUESTIONS pq
        ON pq."id" = qm.question_id
),
exploded_tags AS (                                -- split the tag strings
    SELECT LOWER(TRIM(f.value::string)) AS tag,
           qt.mention_cnt
      FROM question_tags qt,
           LATERAL FLATTEN(INPUT => SPLIT(qt."tags", '|')) f
)
SELECT tag,
       SUM(mention_cnt) AS total_mentions
  FROM exploded_tags
 GROUP BY tag
 ORDER BY total_mentions DESC NULLS LAST
 LIMIT 10;