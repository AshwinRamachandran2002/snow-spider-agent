WITH lines AS (
  SELECT
    f.value::STRING AS "line"
  FROM GITHUB_REPOS.GITHUB_REPOS.SAMPLE_CONTENTS t,
       LATERAL FLATTEN(INPUT => SPLIT(t."content", '\n')) f
)
SELECT
  CASE
    WHEN REGEXP_LIKE("line", '[ \t]$') THEN 'trailing'
    WHEN REGEXP_LIKE("line", '^ ')     THEN 'Space'
    ELSE 'Other'
  END                           AS "line_type",
  COUNT(*)                      AS "total_occurrences"
FROM lines
GROUP BY "line_type"
ORDER BY "line_type";