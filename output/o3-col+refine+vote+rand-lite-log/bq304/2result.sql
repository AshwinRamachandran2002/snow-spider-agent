WITH requested_tags AS (
  SELECT 'android-layout'      AS tag UNION ALL
  SELECT 'android-activity'             UNION ALL
  SELECT 'android-intent'               UNION ALL
  SELECT 'android-edittext'             UNION ALL
  SELECT 'android-fragments'            UNION ALL
  SELECT 'android-recyclerview'         UNION ALL
  SELECT 'listview'                     UNION ALL
  SELECT 'android-actionbar'            UNION ALL
  SELECT 'google-maps'                  UNION ALL
  SELECT 'android-asynctask'
),
qualified AS (
  SELECT
    rt.tag,
    q.id,
    q.title,
    q.view_count,
    ROW_NUMBER() OVER (PARTITION BY rt.tag ORDER BY q.view_count DESC)      AS rn,
    COUNT(*)    OVER (PARTITION BY rt.tag)                                  AS total_per_tag
  FROM `bigquery-public-data.stackoverflow.posts_questions` AS q
  JOIN requested_tags AS rt
    ON q.tags LIKE CONCAT('%', rt.tag, '%')
  WHERE
        (LOWER(q.title) LIKE '%how%' OR LOWER(q.body) LIKE '%how%')
    AND NOT REGEXP_CONTAINS(LOWER(q.title), r'(fail|problem|error|wrong|fix|bug|issue|solve|trouble)')
    AND NOT REGEXP_CONTAINS(LOWER(q.body) , r'(fail|problem|error|wrong|fix|bug|issue|solve|trouble)')
)
SELECT
  tag,
  id,
  title,
  view_count
FROM qualified
WHERE total_per_tag >= 50   -- keep only tags with at least 50 matches
  AND rn <= 50              -- top-50 per such tag by view_count
ORDER BY tag, view_count DESC;