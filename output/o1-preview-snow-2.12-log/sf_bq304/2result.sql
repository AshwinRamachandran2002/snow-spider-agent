(
SELECT
  'android-layout' AS Tag,
  CAST("id" AS STRING) AS Question_ID,
  CAST("title" AS STRING) AS Title,
  CAST("view_count" AS STRING) AS View_Count
FROM STACKOVERFLOW.STACKOVERFLOW.POSTS_QUESTIONS
WHERE "title" ILIKE 'how%'
  AND ('|' || "tags" || '|') ILIKE '%|android-layout|%'
  AND "title" NOT ILIKE '%fail%'
  AND "title" NOT ILIKE '%problem%'
  AND "title" NOT ILIKE '%error%'
  AND "title" NOT ILIKE '%wrong%'
  AND "title" NOT ILIKE '%fix%'
  AND "title" NOT ILIKE '%bug%'
  AND "title" NOT ILIKE '%issue%'
  AND "title" NOT ILIKE '%solve%'
  AND "title" NOT ILIKE '%trouble%'
ORDER BY "view_count" DESC NULLS LAST
LIMIT 50
)
UNION ALL
(
SELECT
  'android-activity' AS Tag,
  CAST("id" AS STRING) AS Question_ID,
  CAST("title" AS STRING) AS Title,
  CAST("view_count" AS STRING) AS View_Count
FROM STACKOVERFLOW.STACKOVERFLOW.POSTS_QUESTIONS
WHERE "title" ILIKE 'how%'
  AND ('|' || "tags" || '|') ILIKE '%|android-activity|%'
  AND "title" NOT ILIKE '%fail%'
  AND "title" NOT ILIKE '%problem%'
  AND "title" NOT ILIKE '%error%'
  AND "title" NOT ILIKE '%wrong%'
  AND "title" NOT ILIKE '%fix%'
  AND "title" NOT ILIKE '%bug%'
  AND "title" NOT ILIKE '%issue%'
  AND "title" NOT ILIKE '%solve%'
  AND "title" NOT ILIKE '%trouble%'
ORDER BY "view_count" DESC NULLS LAST
LIMIT 50
)
UNION ALL
(
SELECT
  'android-intent' AS Tag,
  CAST("id" AS STRING) AS Question_ID,
  CAST("title" AS STRING) AS Title,
  CAST("view_count" AS STRING) AS View_Count
FROM STACKOVERFLOW.STACKOVERFLOW.POSTS_QUESTIONS
WHERE "title" ILIKE 'how%'
  AND ('|' || "tags" || '|') ILIKE '%|android-intent|%'
  AND "title" NOT ILIKE '%fail%'
  AND "title" NOT ILIKE '%problem%'
  AND "title" NOT ILIKE '%error%'
  AND "title" NOT ILIKE '%wrong%'
  AND "title" NOT ILIKE '%fix%'
  AND "title" NOT ILIKE '%bug%'
  AND "title" NOT ILIKE '%issue%'
  AND "title" NOT ILIKE '%solve%'
  AND "title" NOT ILIKE '%trouble%'
ORDER BY "view_count" DESC NULLS LAST
LIMIT 50
)
UNION ALL
(
SELECT
  'android-edittext' AS Tag,
  CAST("id" AS STRING) AS Question_ID,
  CAST("title" AS STRING) AS Title,
  CAST("view_count" AS STRING) AS View_Count
FROM STACKOVERFLOW.STACKOVERFLOW.POSTS_QUESTIONS
WHERE "title" ILIKE 'how%'
  AND ('|' || "tags" || '|') ILIKE '%|android-edittext|%'
  AND "title" NOT ILIKE '%fail%'
  AND "title" NOT ILIKE '%problem%'
  AND "title" NOT ILIKE '%error%'
  AND "title" NOT ILIKE '%wrong%'
  AND "title" NOT ILIKE '%fix%'
  AND "title" NOT ILIKE '%bug%'
  AND "title" NOT ILIKE '%issue%'
  AND "title" NOT ILIKE '%solve%'
  AND "title" NOT ILIKE '%trouble%'
ORDER BY "view_count" DESC NULLS LAST
LIMIT 50
)
UNION ALL
(
SELECT
  'android-fragments' AS Tag,
  CAST("id" AS STRING) AS Question_ID,
  CAST("title" AS STRING) AS Title,
  CAST("view_count" AS STRING) AS View_Count
FROM STACKOVERFLOW.STACKOVERFLOW.POSTS_QUESTIONS
WHERE "title" ILIKE 'how%'
  AND ('|' || "tags" || '|') ILIKE '%|android-fragments|%'
  AND "title" NOT ILIKE '%fail%'
  AND "title" NOT ILIKE '%problem%'
  AND "title" NOT ILIKE '%error%'
  AND "title" NOT ILIKE '%wrong%'
  AND "title" NOT ILIKE '%fix%'
  AND "title" NOT ILIKE '%bug%'
  AND "title" NOT ILIKE '%issue%'
  AND "title" NOT ILIKE '%solve%'
  AND "title" NOT ILIKE '%trouble%'
ORDER BY "view_count" DESC NULLS LAST
LIMIT 50
)
UNION ALL
(
SELECT
  'android-recyclerview' AS Tag,
  CAST("id" AS STRING) AS Question_ID,
  CAST("title" AS STRING) AS Title,
  CAST("view_count" AS STRING) AS View_Count
FROM STACKOVERFLOW.STACKOVERFLOW.POSTS_QUESTIONS
WHERE "title" ILIKE 'how%'
  AND ('|' || "tags" || '|') ILIKE '%|android-recyclerview|%'
  AND "title" NOT ILIKE '%fail%'
  AND "title" NOT ILIKE '%problem%'
  AND "title" NOT ILIKE '%error%'
  AND "title" NOT ILIKE '%wrong%'
  AND "title" NOT ILIKE '%fix%'
  AND "title" NOT ILIKE '%bug%'
  AND "title" NOT ILIKE '%issue%'
  AND "title" NOT ILIKE '%solve%'
  AND "title" NOT ILIKE '%trouble%'
ORDER BY "view_count" DESC NULLS LAST
LIMIT 50
)
UNION ALL
(
SELECT
  'listview' AS Tag,
  CAST("id" AS STRING) AS Question_ID,
  CAST("title" AS STRING) AS Title,
  CAST("view_count" AS STRING) AS View_Count
FROM STACKOVERFLOW.STACKOVERFLOW.POSTS_QUESTIONS
WHERE "title" ILIKE 'how%'
  AND ('|' || "tags" || '|') ILIKE '%|listview|%'
  AND "title" NOT ILIKE '%fail%'
  AND "title" NOT ILIKE '%problem%'
  AND "title" NOT ILIKE '%error%'
  AND "title" NOT ILIKE '%wrong%'
  AND "title" NOT ILIKE '%fix%'
  AND "title" NOT ILIKE '%bug%'
  AND "title" NOT ILIKE '%issue%'
  AND "title" NOT ILIKE '%solve%'
  AND "title" NOT ILIKE '%trouble%'
ORDER BY "view_count" DESC NULLS LAST
LIMIT 50
)
UNION ALL
(
SELECT
  'android-actionbar' AS Tag,
  CAST("id" AS STRING) AS Question_ID,
  CAST("title" AS STRING) AS Title,
  CAST("view_count" AS STRING) AS View_Count
FROM STACKOVERFLOW.STACKOVERFLOW.POSTS_QUESTIONS
WHERE "title" ILIKE 'how%'
  AND ('|' || "tags" || '|') ILIKE '%|android-actionbar|%'
  AND "title" NOT ILIKE '%fail%'
  AND "title" NOT ILIKE '%problem%'
  AND "title" NOT ILIKE '%error%'
  AND "title" NOT ILIKE '%wrong%'
  AND "title" NOT ILIKE '%fix%'
  AND "title" NOT ILIKE '%bug%'
  AND "title" NOT ILIKE '%issue%'
  AND "title" NOT ILIKE '%solve%'
  AND "title" NOT ILIKE '%trouble%'
ORDER BY "view_count" DESC NULLS LAST
LIMIT 50
)
UNION ALL
(
SELECT
  'google-maps' AS Tag,
  CAST("id" AS STRING) AS Question_ID,
  CAST("title" AS STRING) AS Title,
  CAST("view_count" AS STRING) AS View_Count
FROM STACKOVERFLOW.STACKOVERFLOW.POSTS_QUESTIONS
WHERE "title" ILIKE 'how%'
  AND ('|' || "tags" || '|') ILIKE '%|google-maps|%'
  AND "title" NOT ILIKE '%fail%'
  AND "title" NOT ILIKE '%problem%'
  AND "title" NOT ILIKE '%error%'
  AND "title" NOT ILIKE '%wrong%'
  AND "title" NOT ILIKE '%fix%'
  AND "title" NOT ILIKE '%bug%'
  AND "title" NOT ILIKE '%issue%'
  AND "title" NOT ILIKE '%solve%'
  AND "title" NOT ILIKE '%trouble%'
ORDER BY "view_count" DESC NULLS LAST
LIMIT 50
)
UNION ALL
(
SELECT
  'android-asynctask' AS Tag,
  CAST("id" AS STRING) AS Question_ID,
  CAST("title" AS STRING) AS Title,
  CAST("view_count" AS STRING) AS View_Count
FROM STACKOVERFLOW.STACKOVERFLOW.POSTS_QUESTIONS
WHERE "title" ILIKE 'how%'
  AND ('|' || "tags" || '|') ILIKE '%|android-asynctask|%'
  AND "title" NOT ILIKE '%fail%'
  AND "title" NOT ILIKE '%problem%'
  AND "title" NOT ILIKE '%error%'
  AND "title" NOT ILIKE '%wrong%'
  AND "title" NOT ILIKE '%fix%'
  AND "title" NOT ILIKE '%bug%'
  AND "title" NOT ILIKE '%issue%'
  AND "title" NOT ILIKE '%solve%'
  AND "title" NOT ILIKE '%trouble%'
ORDER BY "view_count" DESC NULLS LAST
LIMIT 50
);