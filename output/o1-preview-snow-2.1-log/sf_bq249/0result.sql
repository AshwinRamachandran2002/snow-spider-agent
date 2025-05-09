SELECT
  "Category",
  COUNT(*) AS "Number_of_Files"
FROM (
  SELECT
    CASE
      WHEN REGEXP_LIKE("content", '\s$','m') THEN 'Trailing'
      WHEN REGEXP_LIKE("content", '^\s','m') THEN 'Space'
      ELSE 'Other'
    END AS "Category"
  FROM "GITHUB_REPOS"."GITHUB_REPOS"."SAMPLE_CONTENTS"
  WHERE "binary" = FALSE
) AS "categorized_files"
GROUP BY "Category"
ORDER BY "Category";