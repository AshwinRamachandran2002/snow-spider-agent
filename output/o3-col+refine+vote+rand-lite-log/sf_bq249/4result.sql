SELECT
  "line_type",
  COUNT(*) AS "total_occurrences"
FROM (
  /* split every file’s content into individual lines and classify each line */
  SELECT
    CASE
      WHEN REGEXP_LIKE(ln.value::STRING, '\\s$')          THEN 'trailing'
      WHEN REGEXP_LIKE(ln.value::STRING, '^ ')            THEN 'Space'
      ELSE                                                     'Other'
    END AS "line_type"
  FROM GITHUB_REPOS.GITHUB_REPOS.SAMPLE_CONTENTS sc,
       LATERAL SPLIT_TO_TABLE(sc."content", '\n') ln
) AS classified
GROUP BY "line_type";