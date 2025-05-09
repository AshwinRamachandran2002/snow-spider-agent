/* Top-10 Stack Overflow tags most frequently referenced in Hacker News comments (since 2014-01-01) */
WITH hn_comments AS (   -- collect only 2014-present HN comments that contain an SO-question URL
    SELECT "id",
           "time",
           COALESCE("text", '') AS "text"
    FROM (
        SELECT "id","time",COALESCE("text",'') AS "text"
        FROM STACKOVERFLOW_PLUS.HACKERNEWS.FULL_201510
        WHERE "time" >= 1388534400
        UNION ALL
        SELECT "id","time",COALESCE("text",'')
        FROM STACKOVERFLOW_PLUS.HACKERNEWS.COMMENTSV2
        WHERE "time" >= 1388534400
        UNION ALL
        SELECT "id","time",COALESCE("text",'')
        FROM STACKOVERFLOW_PLUS.HACKERNEWS.FULL_PARTITION_EXTRA
        WHERE "time" >= 1388534400
        UNION ALL
        SELECT "id","time",COALESCE("text",'')
        FROM STACKOVERFLOW_PLUS.HACKERNEWS.COMMENTS
        WHERE "time" >= 1388534400
        UNION ALL
        SELECT "id","time",COALESCE("text",'')
        FROM STACKOVERFLOW_PLUS.HACKERNEWS.COMMENTS_CONVOLUTION
        WHERE "time" >= 1388534400
    )
    WHERE "text" ILIKE '%stackoverflow.com/questions/%'     -- pre-filter to speed up
),
/* pull every Stack Overflow question-id mentioned in a comment */
comment_question_ids AS (
    SELECT  c."id"                                           AS comment_id,
            TRY_CAST(f.value::string AS NUMBER)              AS question_id
    FROM   hn_comments c,
           LATERAL FLATTEN(
                 INPUT => SPLIT(
                             REGEXP_REPLACE(                 -- isolate each numeric id, mark with commas
                                 c."text",
                                 'https?://stackoverflow\\.com/questions/([0-9]+)',
                                 ',\\1,'
                             ),
                             ','
                         )
           ) f
    WHERE  f.value IS NOT NULL
      AND  TRY_CAST(f.value::string AS NUMBER) IS NOT NULL
),
/* count distinct comments referencing each question */
question_mention_counts AS (
    SELECT  question_id,
            COUNT(DISTINCT comment_id) AS mentions
    FROM    comment_question_ids
    GROUP BY question_id
),
/* explode each question’s tags and sum mention counts per tag */
tag_mention_counts AS (
    SELECT  TRIM(tag_elem.value::string)      AS tag,
            SUM(qc.mentions)                  AS total_mentions
    FROM    question_mention_counts qc
            JOIN STACKOVERFLOW_PLUS.STACKOVERFLOW.POSTS_QUESTIONS pq
              ON pq."id" = qc.question_id
            ,LATERAL FLATTEN(
                 INPUT => SPLIT(pq."tags", '|')   -- pipe-delimited tags
             ) tag_elem
    GROUP BY TRIM(tag_elem.value::string)
)
/* return top 10 tags */
SELECT  tag,
        total_mentions
FROM    tag_mention_counts
ORDER BY total_mentions DESC NULLS LAST
LIMIT 10;