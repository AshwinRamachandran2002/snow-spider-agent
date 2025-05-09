SELECT "title"
FROM STACKOVERFLOW.STACKOVERFLOW."POSTS_QUESTIONS",
     LATERAL FLATTEN(input => SPLIT("tags", '|')) AS t
WHERE "title" ILIKE '%how%'
  AND t.value IN ('android', 'android-layout', 'android-activity', 'android-intent')
ORDER BY "view_count" DESC NULLS LAST
LIMIT 1;