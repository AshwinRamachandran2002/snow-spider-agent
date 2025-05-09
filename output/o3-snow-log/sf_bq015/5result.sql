WITH hn_comments AS (   /* gather every Hacker News comment */
    SELECT "text","time"  FROM STACKOVERFLOW_PLUS.HACKERNEWS.FULL_201510
    UNION ALL
    SELECT "text","time"  FROM STACKOVERFLOW_PLUS.HACKERNEWS.FULL_PARTITIONED
    UNION ALL
    SELECT "text","time"  FROM STACKOVERFLOW_PLUS.HACKERNEWS.COMMENTSV2
    UNION ALL
    SELECT "text","time"  FROM STACKOVERFLOW_PLUS.HACKERNEWS.FULL_PARTITION_EXTRA
    UNION ALL
    SELECT "text","time"  FROM STACKOVERFLOW_PLUS.HACKERNEWS.COMMENTS
    UNION ALL
    SELECT "text","time"  FROM STACKOVERFLOW_PLUS.HACKERNEWS.COMMENTS_CONVOLUTION
),
/* keep only comments from 2014-01-01 on that contain a stackoverflow question-URL;
   extract the question-id (first capturing group of the regex)               */
mentions AS (
    SELECT
        TO_NUMBER(
            REGEXP_SUBSTR("text",
                          'stackoverflow\\.com/questions/([0-9]+)',
                          1,                               -- start position
                          1,                               -- 1st occurrence
                          'e',                             -- return group
                          1)                               -- group #1 = id
        )         AS question_id
    FROM hn_comments
    WHERE "time" >= 1388534400                         -- 2014-01-01 UTC
      AND REGEXP_SUBSTR("text",
                        'stackoverflow\\.com/questions/([0-9]+)',
                        1,1,'e',1) IS NOT NULL
),
/* join each mentioned id to the real Stack Overflow question to get its tags */
question_tags AS (
    SELECT m.question_id,
           q."tags"
    FROM mentions               m
    JOIN STACKOVERFLOW_PLUS.STACKOVERFLOW.POSTS_QUESTIONS q
          ON q."id" = m.question_id
),
/* explode the tag string (delimiter = '|') into individual rows               */
exploded_tags AS (
    SELECT
        LOWER(TRIM(f.value::STRING)) AS tag
    FROM question_tags qt,
         LATERAL FLATTEN(input => SPLIT(qt."tags",'|')) f
)
/* count mentions per tag and return the top 10                                */
SELECT
    tag,
    COUNT(*) AS mention_count
FROM exploded_tags
GROUP BY tag
ORDER BY mention_count DESC NULLS LAST
LIMIT 10;