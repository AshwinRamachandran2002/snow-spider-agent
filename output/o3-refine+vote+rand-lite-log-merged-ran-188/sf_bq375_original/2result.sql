SELECT
  file_type,
  file_count
FROM (
  SELECT
    CASE LOWER(SPLIT_PART("path", '.', -1))
      WHEN 'py'    THEN 'Python (.py)'
      WHEN 'c'     THEN 'C (.c)'
      WHEN 'ipynb' THEN 'Jupyter Notebook (.ipynb)'
      WHEN 'java'  THEN 'Java (.java)'
      WHEN 'js'    THEN 'JavaScript (.js)'
    END                                   AS file_type,
    COUNT(*)                              AS file_count
  FROM GITHUB_REPOS.GITHUB_REPOS.SAMPLE_FILES
  WHERE LOWER(SPLIT_PART("path", '.', -1)) IN ('py','c','ipynb','java','js')
    AND (LENGTH("path") - LENGTH(REPLACE("path", '/', ''))) > 10
  GROUP BY file_type
)
ORDER BY file_count DESC NULLS LAST, file_type
LIMIT 1;