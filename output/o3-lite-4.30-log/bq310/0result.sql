SELECT
  title
FROM
  `bigquery-public-data.stackoverflow.posts_questions`
WHERE
  LOWER(title) LIKE 'how %'
  AND (
        IFNULL(LOWER(tags), '') LIKE '%android-layout%'   OR
        IFNULL(LOWER(tags), '') LIKE '%android-activity%' OR
        IFNULL(LOWER(tags), '') LIKE '%android-intent%'   OR
        IFNULL(LOWER(tags), '') LIKE '%android-fragment%' OR
        IFNULL(LOWER(tags), '') LIKE '%android-viewpager%' OR
        IFNULL(LOWER(tags), '') LIKE '%android%'
      )
ORDER BY
  view_count DESC,
  id
LIMIT 1;