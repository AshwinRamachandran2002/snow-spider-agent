-- Task: Retrieve the number of forward citations within 1 year after the application date for U.S. patents that have both backward citations within 1 year before the application date and forward citations within 1 year after the application date. From these patents, select the one with the highest number of backward citations within 1 year before the application date, and return its number of forward citations within 1 year after the application date. The result should be limited to one patent, sorted by the number of backward citations in descending order.
SELECT filterData."fwrdCitations_3"
FROM
  PATENTSVIEW.PATENTSVIEW.APPLICATION AS app
JOIN (
  SELECT DISTINCT 
    cpc."patent_id", 
    IFNULL(citation_3."bkwdCitations_3", 0) AS "bkwdCitations_3", 
    IFNULL(citation_3."fwrdCitations_3", 0) AS "fwrdCitations_3"
  FROM
    PATENTSVIEW.PATENTSVIEW.CPC_CURRENT AS cpc
  LEFT JOIN (
    SELECT 
      b."patent_id", 
      b."bkwdCitations_3", 
      f."fwrdCitations_3"
    FROM 
      (SELECT 
         cited."patent_id",
         COUNT(*) AS "fwrdCitations_3"
       FROM 
         PATENTSVIEW.PATENTSVIEW.USPATENTCITATION AS cited
       JOIN
         PATENTSVIEW.PATENTSVIEW.APPLICATION AS apps
         ON cited."patent_id" = apps."patent_id"
       WHERE
         apps."country" = 'US'
         AND cited."date" >= apps."date"
         AND TRY_CAST(cited."date" AS DATE) <= DATEADD(YEAR, 1, TRY_CAST(apps."date" AS DATE)) -- Citation within 1 year
       GROUP BY 
         cited."patent_id"
      ) AS f
    JOIN (
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
        AND cited."date" < apps."date"
        AND TRY_CAST(cited."date" AS DATE) >= DATEADD(YEAR, -1, TRY_CAST(apps."date" AS DATE)) -- Citation within 1 year before
      GROUP BY 
        cited."patent_id"
    ) AS b
    ON b."patent_id" = f."patent_id"
    WHERE 
      b."bkwdCitations_3" IS NOT NULL
      AND f."fwrdCitations_3" IS NOT NULL
  ) AS citation_3 
  ON cpc."patent_id" = citation_3."patent_id"
) AS filterData
ON app."patent_id" = filterData."patent_id"
ORDER BY filterData."bkwdCitations_3" DESC
LIMIT 1;