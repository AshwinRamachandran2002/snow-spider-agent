SELECT "title"
FROM (
    SELECT "title",
           "view_count"
    FROM STACKOVERFLOW.STACKOVERFLOW."POSTS_QUESTIONS"
    WHERE LOWER("title") LIKE '%how%'
      AND (
            "tags" ILIKE '%android-layout%' 
         OR "tags" ILIKE '%android-activity%'
         OR "tags" ILIKE '%android-intent%'
      )
    ORDER BY "view_count" DESC NULLS LAST
    LIMIT 1
) AS t;