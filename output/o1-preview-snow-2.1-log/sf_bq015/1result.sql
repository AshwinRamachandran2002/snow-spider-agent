WITH hackernews_so_questions AS (
    SELECT DISTINCT TO_NUMBER(REGEXP_SUBSTR("url", '/questions/([0-9]+)', 1, 1, 'e', 1)) AS "question_id"
    FROM "STACKOVERFLOW_PLUS"."HACKERNEWS"."STORIES"
    WHERE "url" ILIKE '%stackoverflow.com/questions/%'
      AND "time" >= 1388534400
),
so_question_tags AS (
    SELECT pq."id", pq."tags"
    FROM "STACKOVERFLOW_PLUS"."STACKOVERFLOW"."POSTS_QUESTIONS" pq
    JOIN hackernews_so_questions hq ON pq."id" = hq."question_id"
)
SELECT LOWER(TRIM(tag.value)) AS "Tag", COUNT(*) AS "Count"
FROM so_question_tags,
LATERAL FLATTEN(input => SPLIT(so_question_tags."tags", '|')) tag
GROUP BY "Tag"
ORDER BY "Count" DESC NULLS LAST
LIMIT 10;