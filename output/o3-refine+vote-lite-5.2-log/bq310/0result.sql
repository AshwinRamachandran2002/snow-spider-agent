SELECT
  title
FROM
  `bigquery-public-data.stackoverflow.posts_questions`
WHERE
  LOWER(title) LIKE '%how%'                                                -- “how” questions
  AND (
        REGEXP_CONTAINS(tags, r'(^|\|)android-layout(\||$)')   OR
        REGEXP_CONTAINS(tags, r'(^|\|)android-activity(\||$)') OR
        REGEXP_CONTAINS(tags, r'(^|\|)android-intent(\||$)')   OR
        REGEXP_CONTAINS(tags, r'(^|\|)android-fragment(\||$)') OR
        REGEXP_CONTAINS(tags, r'(^|\|)android-view(\||$)')                 -- add more tags here if desired
      )
ORDER BY
  view_count DESC,            -- most‑viewed first
  score DESC                  -- tie‑breaker
LIMIT 1;