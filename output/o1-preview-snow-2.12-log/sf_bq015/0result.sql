WITH question_mentions AS (
    SELECT
        TRY_TO_NUMBER(REGEXP_SUBSTR("text", 'stackoverflow\\.com/questions/([0-9]+)', 1, 1, 'e', 1)) AS "question_id",
        COUNT(*) AS "mention_count"
    FROM "STACKOVERFLOW_PLUS"."HACKERNEWS"."COMMENTSV2"
    WHERE "timestamp" >= 1388534400000000
      AND "text" ILIKE '%stackoverflow.com/questions/%'
      AND REGEXP_SUBSTR("text", 'stackoverflow\\.com/questions/([0-9]+)', 1, 1, 'e', 1) IS NOT NULL
    GROUP BY "question_id"
),
question_tags AS (
    SELECT
        q."id" AS "question_id",
        q."tags",
        m."mention_count"
    FROM "STACKOVERFLOW_PLUS"."STACKOVERFLOW"."POSTS_QUESTIONS" q
    JOIN question_mentions m ON q."id" = m."question_id"
),
exploded_tags AS (
    SELECT
        m."question_id",
        m."mention_count",
        SPLIT(m."tags", '|') AS "tag_list"
    FROM question_tags m
),
tag_counts AS (
    SELECT
        CAST(t.value AS STRING) AS "Tag",
        m."mention_count" AS "MentionCount"
    FROM exploded_tags m,
         LATERAL FLATTEN(input => m."tag_list") t
)
SELECT
    "Tag",
    SUM("MentionCount") AS "TotalMentions"
FROM tag_counts
WHERE "Tag" IS NOT NULL
GROUP BY "Tag"
ORDER BY "TotalMentions" DESC NULLS LAST
LIMIT 10;