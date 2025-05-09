SELECT
  CASE
    WHEN f.value::STRING RLIKE '\\s$' THEN 'trailing'          -- ends with whitespace
    WHEN f.value::STRING LIKE ' %'    THEN 'Space'             -- starts with a space
    ELSE 'Other'                                                -- all other lines
  END                                               AS "line_type",
  COUNT(*)                                          AS "total_occurrences"
FROM GITHUB_REPOS.GITHUB_REPOS.SAMPLE_CONTENTS c,
     LATERAL FLATTEN(INPUT => SPLIT(c."content", '\n')) f
GROUP BY "line_type"
ORDER BY "line_type";