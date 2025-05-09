/*  Top‑50 most‑viewed “how” questions per specified Android tag (only tags with ≥ 50 hits)  */
WITH base AS (                 -- retain only “how” questions, remove troubleshooting ones
  SELECT
    id   AS question_id,
    title,
    body,
    view_count,
    LOWER(tags) AS tags_lc
  FROM `bigquery-public-data.stackoverflow.posts_questions`
  WHERE tags IS NOT NULL
    AND (REGEXP_CONTAINS(LOWER(title), r'\bhow\b')
         OR REGEXP_CONTAINS(LOWER(body) , r'\bhow\b'))
    AND NOT REGEXP_CONTAINS(
          LOWER(COALESCE(title,'') || ' ' || COALESCE(body,'')),
          r'\b(fail|problem|error|wrong|fix|bug|issue|solve|trouble)\b')
),
exploded AS (                  -- explode the “|”-delimited tag string
  SELECT
    b.question_id,
    b.title,
    b.view_count,
    tag
  FROM base AS b
  CROSS JOIN UNNEST(SPLIT(b.tags_lc, '|')) AS tag
  WHERE tag IN ('android-layout','android-activity','android-intent',
                'android-edittext','android-fragments','android-recyclerview',
                'listview','android-actionbar','google-maps','android-asynctask')
),
ranked AS (                    -- rank by views and keep per‑tag totals
  SELECT
    tag,
    question_id,
    view_count,
    title,
    ROW_NUMBER() OVER (PARTITION BY tag ORDER BY view_count DESC) AS rn,
    COUNT(*)    OVER (PARTITION BY tag)                           AS total_per_tag
  FROM exploded
)
SELECT
  tag,
  question_id,
  view_count,
  title
FROM ranked
WHERE total_per_tag >= 50      -- only tags with ≥ 50 qualifying questions
  AND rn <= 50                 -- top‑50 most‑viewed per tag
ORDER BY tag, view_count DESC;