-- Top 50 most‑viewed “how” questions per Android‑related tag
WITH tags_list AS (
  SELECT [
    'android-layout','android-activity','android-intent',
    'android-edittext','android-fragments','android-recyclerview',
    'listview','android-actionbar','google-maps','android-asynctask'
  ] AS tags
),

filtered AS (
  SELECT
    q.id,
    q.title,
    q.body,
    q.view_count,
    tag
  FROM `bigquery-public-data.stackoverflow.posts_questions` AS q
  CROSS JOIN UNNEST(SPLIT(q.tags, '|')) AS tag
  CROSS JOIN tags_list tl
  WHERE tag IN UNNEST(tl.tags)                                   -- tag of interest
    AND (                                                        -- contains “how”
         REGEXP_CONTAINS(LOWER(COALESCE(q.title, '')), r'\bhow\b')
         OR
         REGEXP_CONTAINS(LOWER(COALESCE(q.body , '')), r'\bhow\b')
        )
    AND NOT REGEXP_CONTAINS(                                     -- exclude trouble words
         LOWER(COALESCE(q.title, '') || ' ' || COALESCE(q.body, '')),
         r'fail|problem|error|wrong|fix|bug|issue|solve|trouble'
        )
),

qualified_tags AS (                                              -- keep tags ≥ 50 questions
  SELECT tag
  FROM filtered
  GROUP BY tag
  HAVING COUNT(*) >= 50
),

ranked AS (
  SELECT
    f.tag,
    f.id,
    f.title,
    f.view_count,
    ROW_NUMBER() OVER (PARTITION BY f.tag
                       ORDER BY f.view_count DESC, f.id) AS rn
  FROM filtered AS f
  JOIN qualified_tags USING (tag)
)

SELECT
  tag,
  id,
  title,
  view_count
FROM ranked
WHERE rn <= 50
ORDER BY tag, view_count DESC, id;