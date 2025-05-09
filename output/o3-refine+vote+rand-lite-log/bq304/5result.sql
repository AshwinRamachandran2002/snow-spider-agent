-- Top‑50 most‑viewed “how” questions per Android‑related tag
WITH
-- 1. explode tags and keep only questions that
--    a) have one of the target tags
--    b) contain the word “how” (case‑insensitive) in title or body
--    c) do NOT contain any troubleshooting words
filtered_questions AS (
  SELECT
    id,
    title,
    body,
    COALESCE(view_count, 0) AS view_count,
    tag
  FROM
    `bigquery-public-data.stackoverflow.posts_questions`,
    UNNEST(SPLIT(tags, '|')) AS tag
  WHERE
    tag IN ('android-layout','android-activity','android-intent',
            'android-edittext','android-fragments','android-recyclerview',
            'listview','android-actionbar','google-maps','android-asynctask')
    -- must contain the word “how”
    AND REGEXP_CONTAINS(LOWER(CONCAT(title,' ',body)), r'\bhow\b')
    -- must NOT contain any troubleshooting words
    AND NOT REGEXP_CONTAINS(
          LOWER(CONCAT(title,' ',body)),
          r'\b(fail|problem|error|wrong|fix|bug|issue|solve|trouble)\b')
),

-- 2. keep only tags that have at least 50 qualifying questions
qualified_tags AS (
  SELECT tag
  FROM filtered_questions
  GROUP BY tag
  HAVING COUNT(*) >= 50
),

-- 3. rank questions within each qualified tag by view count
ranked AS (
  SELECT
    fq.tag,
    fq.id,
    fq.title,
    fq.view_count,
    ROW_NUMBER() OVER (PARTITION BY fq.tag
                       ORDER BY fq.view_count DESC, fq.id) AS rn
  FROM filtered_questions AS fq
  JOIN qualified_tags USING (tag)
)

-- 4. return top 50 per tag
SELECT
  tag,
  id,
  title,
  view_count
FROM ranked
WHERE rn <= 50
ORDER BY tag, view_count DESC, id;