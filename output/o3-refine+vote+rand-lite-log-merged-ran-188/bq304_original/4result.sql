-- Top‑50 most‑viewed “how” questions per Android‑related tag
WITH target_tags AS (
  SELECT tag
  FROM UNNEST([
      'android-layout','android-activity','android-intent','android-edittext',
      'android-fragments','android-recyclerview','listview','android-actionbar',
      'google-maps','android-asynctask'
  ]) AS tag
),

candidate_questions AS (
  SELECT
    t.tag,
    q.id            AS question_id,
    q.title,
    COALESCE(q.view_count,0) AS view_count,
    q.creation_date
  FROM `bigquery-public-data.stackoverflow.posts_questions` AS q
  JOIN target_tags           AS t
    ON REGEXP_CONTAINS(q.tags, CONCAT('(^|\\|)', t.tag, '(\\||$)'))
  WHERE
        ( REGEXP_CONTAINS(LOWER(COALESCE(q.title,'')), r'\bhow\b')
       OR REGEXP_CONTAINS(LOWER(COALESCE(q.body ,'')), r'\bhow\b') )
    AND NOT REGEXP_CONTAINS(
          LOWER(CONCAT(COALESCE(q.title,''),' ',COALESCE(q.body,''))),
          r'fail|problem|error|wrong|fix|bug|issue|solve|trouble'
        )
),

tag_with_enough AS (
  SELECT tag
  FROM   candidate_questions
  GROUP  BY tag
  HAVING COUNT(*) >= 50
),

ranked AS (
  SELECT
    c.*,
    ROW_NUMBER() OVER (PARTITION BY c.tag
                       ORDER BY c.view_count DESC, c.question_id) AS rn
  FROM candidate_questions AS c
  JOIN tag_with_enough      AS t USING (tag)
)

SELECT
  tag,
  question_id,
  title,
  view_count,
  creation_date
FROM ranked
WHERE rn <= 50
ORDER BY tag, view_count DESC, question_id;