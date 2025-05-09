WITH candidate_questions AS (
  -- all questions that (1) contain "how" and (2) do **not** contain any
  -- troubleshooting terms, restricted to the 10 Android-related tags
  SELECT
    id,
    title,
    view_count,
    CASE
      WHEN tags LIKE '%android-layout%'        THEN 'android-layout'
      WHEN tags LIKE '%android-activity%'      THEN 'android-activity'
      WHEN tags LIKE '%android-intent%'        THEN 'android-intent'
      WHEN tags LIKE '%android-edittext%'      THEN 'android-edittext'
      WHEN tags LIKE '%android-fragments%'     THEN 'android-fragments'
      WHEN tags LIKE '%android-recyclerview%'  THEN 'android-recyclerview'
      WHEN tags LIKE '%listview%'              THEN 'listview'
      WHEN tags LIKE '%android-actionbar%'     THEN 'android-actionbar'
      WHEN tags LIKE '%google-maps%'           THEN 'google-maps'
      WHEN tags LIKE '%android-asynctask%'     THEN 'android-asynctask'
    END AS target_tag
  FROM `bigquery-public-data.stackoverflow.posts_questions`
  WHERE
        (REGEXP_CONTAINS(LOWER(title), r'\bhow\b')
         OR REGEXP_CONTAINS(LOWER(body),  r'\bhow\b'))
    AND NOT REGEXP_CONTAINS(
          LOWER(CONCAT(title, ' ', body)),
          r'(fail|problem|error|wrong|fix|bug|issue|solve|trouble)'
        )
),
qualified_tags AS (
  -- only keep tags that have at least 50 matching questions
  SELECT target_tag
  FROM candidate_questions
  GROUP BY target_tag
  HAVING COUNT(*) >= 50
),
ranked AS (
  -- rank questions by view count within each qualifying tag
  SELECT
    target_tag,
    id,
    title,
    view_count,
    ROW_NUMBER() OVER (PARTITION BY target_tag ORDER BY view_count DESC) AS rn
  FROM candidate_questions
  WHERE target_tag IN (SELECT target_tag FROM qualified_tags)
)
-- final result: top-50 most-viewed questions per qualifying tag
SELECT
  target_tag,
  id,
  title,
  view_count
FROM ranked
WHERE rn <= 50
ORDER BY target_tag, view_count DESC;