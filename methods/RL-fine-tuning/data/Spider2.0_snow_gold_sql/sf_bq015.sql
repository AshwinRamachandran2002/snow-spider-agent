WITH comment_mentions AS (
    SELECT
        REGEXP_SUBSTR("text", 'stackoverflow\.com/questions/([0-9]+)', 1, 1, 'e', 1) AS question_id
    FROM
        "STACKOVERFLOW_PLUS"."HACKERNEWS"."COMMENTS"
    WHERE
        "time_ts" >= 1388534400000000
        AND "text" ILIKE '%stackoverflow.com/questions/%'
),
question_counts AS (
    SELECT
        TO_NUMBER(question_id) AS question_id,
        COUNT(*) AS mention_count
    FROM
        comment_mentions
    WHERE
        question_id IS NOT NULL
    GROUP BY
        question_id
),
question_tags AS (
    SELECT
        q."id",
        q."tags",
        qc.mention_count
    FROM
        "STACKOVERFLOW_PLUS"."STACKOVERFLOW"."POSTS_QUESTIONS" q
    JOIN
        question_counts qc ON q."id" = qc.question_id
    WHERE
        q."tags" IS NOT NULL AND q."tags" != ''
),
tag_counts AS (
    SELECT
        TRIM(tag."VALUE") AS tag,
        SUM(qt.mention_count) AS "TotalMentions"
    FROM
        question_tags qt,
        LATERAL SPLIT_TO_TABLE(qt."tags", '|') AS tag
    GROUP BY
        tag
),
final_counts AS (
    SELECT
        tag,
        "TotalMentions"
    FROM
        tag_counts
    ORDER BY
        "TotalMentions" DESC NULLS LAST
        LIMIT 10
)
SELECT
    tag,
    "TotalMentions"
FROM
    final_counts;