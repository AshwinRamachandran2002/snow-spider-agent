/* Consolidated metadata for Visium run
   ‘HT264P1‑S1H2Fc2U1Z1Bs1‑H2Bs2‑Test’ plus any scRNA‑seq files
   whose filenames contain the substring “HT264P1”. */
SELECT
    "Filename",
    "HTAN_Parent_Biospecimen_ID"      AS "HTAN Parent Biospecimen ID",
    "Component",
    "File_Format"                     AS "File Format",
    "entityId"                        AS "Entity ID",
    "Run_ID"                          AS "Run ID"
FROM "HTAN_2"."HTAN"."_10XVISIUM_SPATIALTRANSCRIPTOMICS_SCRNASEQ_LEVEL1_METADATA_CURRENT"
WHERE "Run_ID" = 'HT264P1-S1H2Fc2U1Z1Bs1-H2Bs2-Test'

UNION ALL
SELECT
    "Filename",
    "HTAN_Parent_Biospecimen_ID",
    "Component",
    "File_Format",
    "entityId",
    "Run_ID"
FROM "HTAN_2"."HTAN"."_10XVISIUM_SPATIALTRANSCRIPTOMICS_SCRNASEQ_LEVEL2_METADATA_CURRENT"
WHERE "Run_ID" = 'HT264P1-S1H2Fc2U1Z1Bs1-H2Bs2-Test'

UNION ALL
SELECT
    "Filename",
    "HTAN_Parent_Biospecimen_ID",
    "Component",
    "File_Format",
    "entityId",
    "Run_ID"
FROM "HTAN_2"."HTAN"."_10XVISIUM_SPATIALTRANSCRIPTOMICS_SCRNASEQ_LEVEL3_METADATA_CURRENT"
WHERE "Run_ID" = 'HT264P1-S1H2Fc2U1Z1Bs1-H2Bs2-Test'

UNION ALL
SELECT
    "Filename",
    "HTAN_Parent_Biospecimen_ID",
    "Component",
    "File_Format",
    "entityId",
    "Run_ID"
FROM "HTAN_2"."HTAN"."_10XVISIUM_SPATIALTRANSCRIPTOMICS_SCRNASEQ_LEVEL4_METADATA_CURRENT"
WHERE "Run_ID" = 'HT264P1-S1H2Fc2U1Z1Bs1-H2Bs2-Test'

UNION ALL
SELECT
    "Filename",
    "HTAN_Parent_Biospecimen_ID",
    "Component",
    "File_Format",
    "entityId",
    "Run_ID"
FROM "HTAN_2"."HTAN"."_10XVISIUM_SPATIALTRANSCRIPTOMICS_AUXILIARYFILES_METADATA_CURRENT"
WHERE "Run_ID" = 'HT264P1-S1H2Fc2U1Z1Bs1-H2Bs2-Test'

UNION ALL
SELECT
    "Filename",
    "HTAN_Parent_Biospecimen_ID"      AS "HTAN Parent Biospecimen ID",
    "Component",
    "File_Format",
    "entityId",
    NULL                               AS "Run ID"
FROM "HTAN_2"."HTAN"."SCRNASEQ_LEVEL1_METADATA_CURRENT"
WHERE "Filename" ILIKE '%HT264P1%'

UNION ALL
SELECT
    "Filename",
    NULL                               AS "HTAN Parent Biospecimen ID",
    "Component",
    "File_Format",
    "entityId",
    NULL                               AS "Run ID"
FROM "HTAN_2"."HTAN"."SCRNASEQ_LEVEL2_METADATA_CURRENT"
WHERE "Filename" ILIKE '%HT264P1%'

UNION ALL
SELECT
    "Filename",
    NULL                               AS "HTAN Parent Biospecimen ID",
    "Component",
    "File_Format",
    "entityId",
    NULL                               AS "Run ID"
FROM "HTAN_2"."HTAN"."SCRNASEQ_LEVEL3_METADATA_CURRENT"
WHERE "Filename" ILIKE '%HT264P1%'

UNION ALL
SELECT
    "Filename",
    NULL                               AS "HTAN Parent Biospecimen ID",
    "Component",
    "File_Format",
    "entityId",
    NULL                               AS "Run ID"
FROM "HTAN_2"."HTAN"."SCRNASEQ_LEVEL4_METADATA_CURRENT"
WHERE "Filename" ILIKE '%HT264P1%';