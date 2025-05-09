WITH tags AS (
  SELECT 'android-layout' AS tag_name UNION ALL
  SELECT 'android-activity' UNION ALL
  SELECT 'android-intent' UNION ALL
  SELECT 'android-edittext' UNION ALL
  SELECT 'android-fragments' UNION ALL
  SELECT 'android-recyclerview' UNION ALL
  SELECT 'listview' UNION ALL
  SELECT 'android-actionbar' UNION ALL
  SELECT 'google-maps' UNION ALL
  SELECT 'android-asynctask'
),
questions_with_tags AS (
  SELECT
    CAST(q."id" AS STRING) AS id,
    CAST(q."title" AS STRING) AS title,
    CAST(q."view_count" AS INT) AS view_count,
    t.tag_name,
    ROW_NUMBER() OVER (
      PARTITION BY t.tag_name
      ORDER BY q."view_count" DESC NULLS LAST
    ) AS rn
  FROM STACKOVERFLOW.STACKOVERFLOW."POSTS_QUESTIONS" q
  CROSS JOIN tags t
  WHERE ('|' || q."tags" || '|') LIKE '%|' || t.tag_name || '|%'
    AND LOWER(q."title") LIKE '%how%'
    AND LOWER(q."title") NOT LIKE '%fail%'
    AND LOWER(q."title") NOT LIKE '%problem%'
    AND LOWER(q."title") NOT LIKE '%error%'
    AND LOWER(q."title") NOT LIKE '%wrong%'
    AND LOWER(q."title") NOT LIKE '%fix%'
    AND LOWER(q."title") NOT LIKE '%bug%'
    AND LOWER(q."title") NOT LIKE '%issue%'
    AND LOWER(q."title") NOT LIKE '%solve%'
    AND LOWER(q."title") NOT LIKE '%trouble%'
)
SELECT
  q.tag_name AS Tag,
  q.id AS Question_ID,
  q.title AS Title,
  q.view_count AS View_Count
FROM questions_with_tags q
WHERE q.rn <= 50
ORDER BY q.tag_name, q.view_count DESC NULLS LAST;