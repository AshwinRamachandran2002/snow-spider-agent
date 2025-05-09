-- Top 50 most‑viewed “how …” questions (sans troubleshooting words)
-- for each Android–related tag that has at least 50 such questions
WITH base AS (
  SELECT
    id,
    title,
    body,
    view_count,
    tag
  FROM `bigquery-public-data.stackoverflow.posts_questions`,
  UNNEST(SPLIT(tags,'|')) AS tag                  -- explode tags
  WHERE tag IN (
        'android-layout','android-activity','android-intent',
        'android-edittext','android-fragments','android-recyclerview',
        'listview','android-actionbar','google-maps','android-asynctask')
    AND view_count IS NOT NULL

    -- must contain the word “how” (whole word) in title or body
    AND (
      REGEXP_CONTAINS(LOWER(title), r'\bhow\b')
      OR REGEXP_CONTAINS(LOWER(body) , r'\bhow\b')
    )

    -- must NOT contain any troubleshooting terms in title or body
    AND NOT (
      REGEXP_CONTAINS(LOWER(title), r'\b(fail|problem|error|wrong|fix|bug|issue|solve|trouble)\b')
      OR REGEXP_CONTAINS(LOWER(body) , r'\b(fail|problem|error|wrong|fix|bug|issue|solve|trouble)\b')
    )
),

-- keep only tags that have at least 50 qualifying questions
qualified_tags AS (
  SELECT tag
  FROM base
  GROUP BY tag
  HAVING COUNT(*) >= 50
),

filtered AS (
  SELECT b.*
  FROM base b
  JOIN qualified_tags USING (tag)
),

-- rank questions by view count within each tag
ranked AS (
  SELECT
    tag,
    id,
    title,
    view_count,
    ROW_NUMBER() OVER (PARTITION BY tag ORDER BY view_count DESC, id) AS rn
  FROM filtered
)

-- top 50 per qualifying tag
SELECT
  tag,
  id           AS question_id,
  title,
  view_count
FROM ranked
WHERE rn <= 50
ORDER BY tag, rn;