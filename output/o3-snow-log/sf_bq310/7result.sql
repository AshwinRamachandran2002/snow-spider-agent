SELECT  "title"
FROM    STACKOVERFLOW.STACKOVERFLOW.POSTS_QUESTIONS
WHERE   LOWER("title") LIKE 'how%'                              -- “how” question
  AND  (
          "tags" ILIKE '%android-layout%'   OR
          "tags" ILIKE '%android-activity%' OR
          "tags" ILIKE '%android-intent%'   OR
          "tags" ILIKE '%android-%'         -- covers any other android-specific tag
       )
ORDER BY "view_count" DESC NULLS LAST
LIMIT 1;