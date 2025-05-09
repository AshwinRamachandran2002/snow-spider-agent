SELECT LOWER(t.value) AS "Tag", COUNT(*) AS "Count"
FROM STACKOVERFLOW_PLUS.HACKERNEWS."STORIES" s
JOIN STACKOVERFLOW_PLUS.STACKOVERFLOW."POSTS_QUESTIONS" p
  ON TO_NUMBER(REGEXP_SUBSTR(s."url", 'stackoverflow\.com/questions/([0-9]+)', 1, 1, 'e', 1)) = p."id"
, LATERAL FLATTEN(input => SPLIT(p."tags", '|')) t
WHERE s."url" ILIKE '%stackoverflow.com/questions/%' AND s."time" >= 1388534400
GROUP BY LOWER(t.value)
ORDER BY COUNT(*) DESC
LIMIT 10;