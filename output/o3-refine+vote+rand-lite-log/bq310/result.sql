-- Most–viewed “how” question related to Android development
SELECT
  title
FROM
  `bigquery-public-data.stackoverflow.posts_questions`
WHERE
  title IS NOT NULL
  -- question title contains the word “how” (case‑insensitive)
  AND REGEXP_CONTAINS(LOWER(title), r'\bhow\b')
  -- tagged with common Android‑related tags
  AND (
        tags LIKE '%android-layout%'  OR
        tags LIKE '%android-activity%' OR
        tags LIKE '%android-intent%'  OR
        tags LIKE '%android-fragment%'OR
        tags LIKE '%android-service%' OR
        tags LIKE '%android-studio%'  OR
        tags LIKE '%android-manifest%'OR
        tags LIKE '%android-view%'    OR
        tags LIKE '%android-widget%'  OR
        tags LIKE '%android%'         -- generic Android tag as fallback
      )
ORDER BY
  view_count DESC
LIMIT 1;