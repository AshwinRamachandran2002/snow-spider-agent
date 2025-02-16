-- Task: Retrieve the patent title, abstract, and the number of backward citations (i.e., the number of patents cited by the current patent before its filing date) for U.S. patents filed between January 1, 2014, and February 1, 2014. Limit the results to 100 entries.

SELECT
    patent."title",
    patent."abstract",
    IFNULL(b."bkwdCitations", 0) AS "bkwdCitations"
FROM
    "PATENTSVIEW"."PATENTSVIEW"."PATENT" AS patent
JOIN
    "PATENTSVIEW"."PATENTSVIEW"."APPLICATION" AS app
    ON app."patent_id" = patent."id"
LEFT JOIN (
    SELECT
        cited."patent_id",
        IFNULL(COUNT(*), 0) AS "bkwdCitations"
    FROM
        "PATENTSVIEW"."PATENTSVIEW"."USPATENTCITATION" AS cited
    JOIN
        "PATENTSVIEW"."PATENTSVIEW"."APPLICATION" AS apps
        ON cited."patent_id" = apps."patent_id"
    WHERE
        apps."country" = 'US'
        AND TRY_CAST(cited."date" AS DATE) < TRY_CAST(apps."date" AS DATE)
    GROUP BY
        cited."patent_id"
) AS b
ON b."patent_id" = app."patent_id"
WHERE
    TRY_CAST(app."date" AS DATE) >= '2014-01-01'
    AND TRY_CAST(app."date" AS DATE) < '2014-02-01'
LIMIT 100;