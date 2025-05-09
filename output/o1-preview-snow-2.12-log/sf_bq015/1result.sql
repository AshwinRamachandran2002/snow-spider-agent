WITH
  question_mentions AS (
    SELECT
      TO_NUMBER(
        REGEXP_SUBSTR("text", 'stackoverflow\.com/questions/([0-9]+)', 1, 1, 'e')
      ) AS "question_id",
      COUNT(*) AS "mention_count"
    FROM STACKOVERFLOW_PLUS.HACKERNEWS.COMMENTSV2
    WHERE "text" ILIKE '%stackoverflow.com/questions/%'
    GROUP BY "question_id"
    HAVING "question_id" IS NOT NULL
  ),
  question_tags AS (
    SELECT
      pq."id" AS "question_id",
      qm."mention_count",
      SPLIT(pq."tags", '|') AS "tags_array"
    FROM question_mentions qm
    JOIN STACKOVERFLOW_PLUS.STACKOVERFLOW.POSTS_QUESTIONS pq
      ON pq."id" = qm."question_id"
    WHERE pq."tags" IS NOT NULL
  )
SELECT
  tag.value::string AS "Tag",
  SUM(qt."mention_count") AS "TotalMentions"
FROM question_tags qt,
  LATERAL FLATTEN(input => qt."tags_array") tag
GROUP BY "Tag"
ORDER BY "TotalMentions" DESC NULLS LAST
LIMIT 10;