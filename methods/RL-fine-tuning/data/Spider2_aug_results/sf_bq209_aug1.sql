-- Task: Can you list the publication and application numbers of utility patents granted in 2010?

SELECT
    t1."publication_number",
    t1."application_number"
FROM
    PATENTS.PATENTS.PUBLICATIONS t1
WHERE
    TO_DATE(
        CASE
            WHEN t1."grant_date" != 0 THEN TO_CHAR(t1."grant_date")
            ELSE NULL
        END, 
        'YYYYMMDD'
    ) BETWEEN TO_DATE('20100101', 'YYYYMMDD') AND TO_DATE('20101231', 'YYYYMMDD')
LIMIT 100;