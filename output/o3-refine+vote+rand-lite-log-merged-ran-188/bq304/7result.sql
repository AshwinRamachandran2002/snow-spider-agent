WITH filtered AS (
  SELECT
    id,
    title,
    body,
    view_count,
    tags
  FROM `bigquery-public-data.stackoverflow.posts_questions`
  WHERE
    -- must contain the word "how"
    (LOWER(title) LIKE '%how%' OR LOWER(body) LIKE '%how%')
    -- must NOT contain any troubleshooting terms
    AND NOT REGEXP_CONTAINS(
          LOWER(CONCAT(title,' ',body)),
          r'\b(fail|problem|error|wrong|fix|bug|issue|solve|trouble)\b'
        )
),
exploded AS (
  -- split the pipe-delimited tag string into individual rows
  SELECT
    id,
    title,
    view_count,
    tag
  FROM filtered,
  UNNEST(SPLIT(tags,'|')) AS tag
  WHERE tag IN (
      'android-layout','android-activity','android-intent',
      'android-edittext','android-fragments','android-recyclerview',
      'listview','android-actionbar','google-maps','android-asynctask'
  )
),
qualified_tags AS (
  -- keep only tags that have at least 50 qualifying questions
  SELECT tag
  FROM exploded
  GROUP BY tag
  HAVING COUNT(*) >= 50
),
ranked AS (
  -- rank questions within each tag by view count
  SELECT
    id,
    tag,
    title,
    view_count,
    ROW_NUMBER() OVER (PARTITION BY tag ORDER BY view_count DESC) AS rn
  FROM exploded
  WHERE tag IN (SELECT tag FROM qualified_tags)
)
-- top 50 most-viewed questions per qualified tag
SELECT
  id,
  tag,
  title,
  view_count
FROM ranked
WHERE rn <= 50
ORDER BY tag, view_count DESC;