SELECT
    c1."RefNo",
    c1."CaseNo",
    c1."InvNo",
    c1."Clone" AS "CloneNo",
    k."CloneShort",
    k."CloneLong",
    c1."Start" AS "Chr13_Start",
    c1."End" AS "Chr13_End",
    c1."Type" AS "Chr13_Type",
    c2."Start" AS "Chr17_Start",
    c2."End" AS "Chr17_End",
    c2."Type" AS "Chr17_Type",
    c3."Start" AS "Chr11_Start",
    c3."End" AS "Chr11_End",
    c3."Type" AS "Chr11_Type"
FROM
    "MITELMAN"."PROD"."CYTOCONVERTED" c1
    JOIN "MITELMAN"."PROD"."CYTOCONVERTED" c2
        ON c1."RefNo" = c2."RefNo"
        AND c1."CaseNo" = c2."CaseNo"
        AND c1."InvNo" = c2."InvNo"
        AND c1."Clone" = c2."Clone"
    JOIN "MITELMAN"."PROD"."CYTOCONVERTED" c3
        ON c1."RefNo" = c3."RefNo"
        AND c1."CaseNo" = c3."CaseNo"
        AND c1."InvNo" = c3."InvNo"
        AND c1."Clone" = c3."Clone"
    JOIN "MITELMAN"."PROD"."KARYCLONE" k
        ON c1."RefNo" = k."RefNo"
        AND c1."CaseNo" = k."CaseNo"
        AND c1."InvNo" = k."InvNo"
        AND c1."Clone" = k."CloneNo"
WHERE
    c1."Chr" = 'chr13' AND
    c1."Type" = 'Loss' AND
    c1."Start" <= 48481890 AND c1."End" >= 48303751 AND
    c2."Chr" = 'chr17' AND
    c2."Type" = 'Loss' AND
    c3."Chr" = 'chr11' AND
    c3."Type" = 'Gain' AND
    c3."Start" <= 108369102 AND c3."End" >= 108223067;