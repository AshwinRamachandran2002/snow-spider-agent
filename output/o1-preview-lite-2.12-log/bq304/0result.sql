SELECT tag AS Tag, id AS Question_ID, title AS Title, view_count AS View_Count
FROM (
  SELECT 
    tag, id, title, view_count,
    ROW_NUMBER() OVER (PARTITION BY tag ORDER BY view_count DESC) AS rn
  FROM (
    SELECT 
      id, title, view_count,
      SPLIT(REGEXP_REPLACE(tags, r'^<|>$', ''), '><') AS tag_list
    FROM `bigquery-public-data.stackoverflow.posts_questions`
    WHERE LOWER(title) LIKE 'how%'
      AND NOT (
        LOWER(title) LIKE '%fail%' OR
        LOWER(title) LIKE '%problem%' OR
        LOWER(title) LIKE '%error%' OR
        LOWER(title) LIKE '%wrong%' OR
        LOWER(title) LIKE '%fix%' OR
        LOWER(title) LIKE '%bug%' OR
        LOWER(title) LIKE '%issue%' OR
        LOWER(title) LIKE '%solve%' OR
        LOWER(title) LIKE '%trouble%'
      )
  )
  CROSS JOIN UNNEST(tag_list) AS tag
  WHERE tag IN ('android-layout', 'android-activity', 'android-intent', 'android-edittext',
                'android-fragments', 'android-recyclerview', 'listview', 'android-actionbar',
                'google-maps', 'android-asynctask')
)
WHERE rn <= 50
ORDER BY tag, view_count DESC;