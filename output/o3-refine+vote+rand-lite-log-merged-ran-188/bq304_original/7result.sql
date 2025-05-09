-- Top 50 most–viewed “how” questions per Android‑related tag
WITH
target_tags AS (
  -- list of tags we care about
  SELECT tag
  FROM UNNEST([
    'android-layout', 'android-activity', 'android-intent', 'android-edittext',
    'android-fragments', 'android-recyclerview', 'listview',
    'android-actionbar', 'google-maps', 'android-asynctask'
  ]) AS tag
),

filtered AS (
  -- questions that (1) have one of the target tags,
  -- (2) contain the word “how”, and (3) do NOT contain any troubleshooting terms
  SELECT
    q.id,
    q.title,
    q.body,
    COALESCE(q.view_count,0) AS view_count,
    t.tag
  FROM `bigquery-public-data.stackoverflow.posts_questions` AS q
  CROSS JOIN UNNEST(SPLIT(q.tags, '|')) AS tag_in_post          -- explode tags
  JOIN target_tags            AS t ON t.tag = tag_in_post       -- keep only target tags
  WHERE
    -- “how” must appear (word boundary, case‑insensitive)
    REGEXP_CONTAINS(
      LOWER(CONCAT(IFNULL(q.title,''), ' ', IFNULL(q.body,''))),
      r'\bhow\b'
    )
    -- none of these troubleshooting terms may appear
    AND NOT REGEXP_CONTAINS(
      LOWER(CONCAT(IFNULL(q.title,''), ' ', IFNULL(q.body,''))),
      r'\b(fail|problem|error|wrong|fix|bug|issue|solve|trouble)\b'
    )
),

tag_counts AS (
  -- keep only tags with at least 50 qualifying questions
  SELECT tag, COUNT(*) AS cnt
  FROM filtered
  GROUP BY tag
  HAVING cnt >= 50
),

ranked AS (
  -- rank questions by view count within each tag
  SELECT
    f.tag,
    f.id,
    f.title,
    f.view_count,
    ROW_NUMBER() OVER (PARTITION BY f.tag
                       ORDER BY f.view_count DESC, f.id ASC) AS rn
  FROM filtered AS f
  JOIN tag_counts USING (tag)
)

-- final result: top 50 per qualifying tag
SELECT
  tag,
  id           AS question_id,
  title,
  view_count
FROM ranked
WHERE rn <= 50
ORDER BY tag, rn;