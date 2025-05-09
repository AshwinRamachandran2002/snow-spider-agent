SELECT
  Tag,
  CAST(Question_ID AS STRING) AS Question_ID,
  REPLACE(Title, '"', "'") AS Title,
  View_Count
FROM (
  SELECT
    tag AS Tag,
    id AS Question_ID,
    title AS Title,
    view_count AS View_Count,
    ROW_NUMBER() OVER (PARTITION BY tag ORDER BY view_count DESC) AS rn
  FROM
    `bigquery-public-data.stackoverflow.posts_questions`,
    UNNEST(SPLIT(tags, '|')) AS tag
  WHERE
    LOWER(title) LIKE 'how%'
    AND LOWER(title) NOT LIKE '%fail%'
    AND LOWER(title) NOT LIKE '%problem%'
    AND LOWER(title) NOT LIKE '%error%'
    AND LOWER(title) NOT LIKE '%wrong%'
    AND LOWER(title) NOT LIKE '%fix%'
    AND LOWER(title) NOT LIKE '%bug%'
    AND LOWER(title) NOT LIKE '%issue%'
    AND LOWER(title) NOT LIKE '%solve%'
    AND LOWER(title) NOT LIKE '%trouble%'
    AND tag IN ('android-layout', 'android-activity', 'android-intent', 'android-edittext',
                'android-fragments', 'android-recyclerview', 'listview', 'android-actionbar',
                'google-maps', 'android-asynctask')
)
WHERE rn <= 50
ORDER BY Tag, View_Count DESC;