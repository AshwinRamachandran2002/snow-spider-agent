-- Top-50 most-viewed “how …” questions for each eligible Android-related tag
WITH target_tags AS (
  SELECT 'android-layout'       AS tag UNION ALL
  SELECT 'android-activity'     UNION ALL
  SELECT 'android-intent'       UNION ALL
  SELECT 'android-edittext'     UNION ALL
  SELECT 'android-fragments'    UNION ALL
  SELECT 'android-recyclerview' UNION ALL
  SELECT 'listview'             UNION ALL
  SELECT 'android-actionbar'    UNION ALL
  SELECT 'google-maps'          UNION ALL
  SELECT 'android-asynctask'
),

qualified AS (
  SELECT
    ttag                                   AS tag,
    q.id                                   AS question_id,
    q.title,
    q.view_count,
    ROW_NUMBER() OVER (PARTITION BY ttag
                       ORDER BY q.view_count DESC)  AS rn
  FROM `bigquery-public-data.stackoverflow.posts_questions` AS q
  CROSS JOIN UNNEST(SPLIT(q.tags,'|')) AS ttag          -- explode tag list
  JOIN target_tags tt
    ON tt.tag = ttag                                    -- keep only target tags
  WHERE (LOWER(q.title) LIKE '%how%' OR LOWER(q.body) LIKE '%how%')
    AND NOT REGEXP_CONTAINS(LOWER(q.title),
          r'(fail|problem|error|wrong|fix|bug|issue|solve|trouble)')
    AND NOT REGEXP_CONTAINS(LOWER(q.body),
          r'(fail|problem|error|wrong|fix|bug|issue|solve|trouble)')
),

eligible_tags AS (
  SELECT tag
  FROM   qualified
  GROUP  BY tag
  HAVING COUNT(*) >= 50                            -- require ≥ 50 qualifying Qs
),

top50 AS (
  SELECT *
  FROM   qualified
  WHERE  tag IN (SELECT tag FROM eligible_tags)
    AND  rn <= 50                                  -- top-50 by views per tag
)

SELECT
  tag,
  question_id,
  title,
  view_count
FROM   top50
ORDER  BY tag, view_count DESC;