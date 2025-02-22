-- Task: Retrieve the patent id, title, application date, and abstract text for U.S. patents that belong to specific CPC categories, such as subsection 'C05' or group 'A01G'. Sort the results by application date and return up to 100 matching records.
SELECT
    app."patent_id" AS "patent_id",
    patent."title",
    app."date" AS "application_date",
    summary."text" AS "summary_text"
FROM
    PATENTSVIEW.PATENTSVIEW.BRF_SUM_TEXT AS summary
JOIN
    PATENTSVIEW.PATENTSVIEW.PATENT AS patent
    ON summary."patent_id" = patent."id"
JOIN
    PATENTSVIEW.PATENTSVIEW.APPLICATION AS app
    ON app."patent_id" = summary."patent_id"
JOIN
    PATENTSVIEW.PATENTSVIEW.CPC_CURRENT AS cpc
    ON cpc."patent_id" = app."patent_id"
WHERE
    cpc."subsection_id" = 'C05'
    OR cpc."group_id" = 'A01G'
ORDER BY
    app."date"
LIMIT 100;