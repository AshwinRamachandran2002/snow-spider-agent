SELECT TRIM(tag) AS "Tag", COUNT(*) AS "Count"
FROM (
  SELECT p."id", TRIM(f.value) AS tag
  FROM STACKOVERFLOW_PLUS.STACKOVERFLOW.POSTS_QUESTIONS p,
       LATERAL FLATTEN(INPUT => SPLIT(p."tags", '|')) f
  WHERE p."id" IN (
    SELECT CAST(REGEXP_SUBSTR("url", '/questions/([0-9]+)', 1, 1, 'e') AS NUMBER)
    FROM STACKOVERFLOW_PLUS.HACKERNEWS.STORIES
    WHERE "url" ILIKE '%stackoverflow.com/questions/%'
      AND "time" >= 1388534400  -- UNIX timestamp for Jan 1, 2014
    )
    AND f.value IS NOT NULL AND f.value != ''
)
GROUP BY "Tag"
ORDER BY "Count" DESC NULLS LAST
LIMIT 10;