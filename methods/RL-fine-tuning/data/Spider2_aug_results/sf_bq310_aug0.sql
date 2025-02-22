-- Task: Retrieve the title of the most viewed question on StackOverflow that contains "how" in its title (case-insensitive) and is tagged with one of the following tags: 'android', 'android-layout', 'android-activity', or 'android-intent'.

SELECT "title"
FROM STACKOVERFLOW.STACKOVERFLOW."POSTS_QUESTIONS",
     LATERAL FLATTEN(input => SPLIT("tags", '|')) AS t
WHERE "title" ILIKE '%how%'
  AND t.value IN ('android', 'android-layout', 'android-activity', 'android-intent')
ORDER BY "view_count" DESC NULLS LAST
LIMIT 1;