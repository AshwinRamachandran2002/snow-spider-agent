WITH first_answers AS (
  -- for every question, get timestamp of its *first* answer
  SELECT
    q.id                    AS question_id,
    q.creation_date         AS question_time,
    MIN(a.creation_date)    AS first_answer_time
  FROM `bigquery-public-data.stackoverflow.posts_questions` AS q
  JOIN `bigquery-public-data.stackoverflow.posts_answers`   AS a
    ON a.parent_id = q.id
  GROUP BY question_id, question_time
),
weekday_stats AS (
  -- per weekday: total questions vs. questions answered ≤ 60 minutes
  SELECT
    EXTRACT(DAYOFWEEK FROM question_time)                         AS dow,          -- 1-Sun … 7-Sat
    FORMAT_TIMESTAMP('%A', question_time)                         AS weekday_name,
    COUNT(*)                                                      AS total_q,
    COUNTIF(
      TIMESTAMP_DIFF(first_answer_time, question_time, MINUTE)
      <= 60
    )                                                            AS answered_within_hour
  FROM first_answers
  GROUP BY dow, weekday_name
),
ranked AS (
  -- turn counts into percentages and rank them
  SELECT
    weekday_name,
    100 * answered_within_hour / total_q                         AS pct_within_hour,
    ROW_NUMBER() OVER (ORDER BY 100 * answered_within_hour / total_q DESC) AS rnk
  FROM weekday_stats
)
-- the weekday with the 3-rd highest percentage of answers within an hour
SELECT
  weekday_name  AS day_of_week,
  pct_within_hour
FROM ranked
WHERE rnk = 3;