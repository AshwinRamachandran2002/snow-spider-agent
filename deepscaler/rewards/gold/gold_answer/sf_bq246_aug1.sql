-- Task: Retrieve U.S. patents and the number of backward citations within 1 year before the application date, and return the patent with the most backward citations.
SELECT 
  cited."patent_id",
  COUNT(*) AS "bkwdCitations_3"
FROM 
  PATENTSVIEW.PATENTSVIEW.USPATENTCITATION AS cited
JOIN
  PATENTSVIEW.PATENTSVIEW.APPLICATION AS apps
  ON cited."patent_id" = apps."patent_id"
WHERE
  apps."country" = 'US'
  AND TRY_CAST(cited."date" AS DATE) < TRY_CAST(apps."date" AS DATE)
  AND TRY_CAST(cited."date" AS DATE) >= DATEADD(YEAR, -1, TRY_CAST(apps."date" AS DATE))
GROUP BY 
  cited."patent_id"
ORDER BY
  "bkwdCitations_3" DESC
LIMIT 1;