/*  Consolidate spatial-transcriptomics (levels 1-4 + auxiliary) together with
    scRNA-seq metadata files (levels 1-4) that correspond to the run
    “HT264P1-S1H2Fc2U1Z1Bs1-H2Bs2-Test”.                                   */

SELECT DISTINCT
       "Filename",
       "HTAN_Parent_Biospecimen_ID",
       "Component",
       "File_Format",
       "entityId",
       "Run_ID"
FROM
(
    /* -------- 10x Visium spatial-transcriptomics -------- */
    SELECT "Filename","HTAN_Parent_Biospecimen_ID","Component",
           "File_Format","entityId","Run_ID"
    FROM HTAN_2.HTAN."_10XVISIUM_SPATIALTRANSCRIPTOMICS_SCRNASEQ_LEVEL1_METADATA_CURRENT"
    WHERE "Run_ID" ILIKE '%HT264P1-S1H2Fc2U1Z1Bs1-H2Bs2-Test%'

    UNION ALL
    SELECT "Filename","HTAN_Parent_Biospecimen_ID","Component",
           "File_Format","entityId","Run_ID"
    FROM HTAN_2.HTAN."_10XVISIUM_SPATIALTRANSCRIPTOMICS_SCRNASEQ_LEVEL2_METADATA_CURRENT"
    WHERE "Run_ID" ILIKE '%HT264P1-S1H2Fc2U1Z1Bs1-H2Bs2-Test%'

    UNION ALL
    SELECT "Filename","HTAN_Parent_Biospecimen_ID","Component",
           "File_Format","entityId","Run_ID"
    FROM HTAN_2.HTAN."_10XVISIUM_SPATIALTRANSCRIPTOMICS_SCRNASEQ_LEVEL3_METADATA_CURRENT"
    WHERE "Run_ID" ILIKE '%HT264P1-S1H2Fc2U1Z1Bs1-H2Bs2-Test%'

    UNION ALL
    SELECT "Filename","HTAN_Parent_Biospecimen_ID","Component",
           "File_Format","entityId","Run_ID"
    FROM HTAN_2.HTAN."_10XVISIUM_SPATIALTRANSCRIPTOMICS_SCRNASEQ_LEVEL4_METADATA_CURRENT"
    WHERE "Run_ID" ILIKE '%HT264P1-S1H2Fc2U1Z1Bs1-H2Bs2-Test%'

    UNION ALL
    SELECT "Filename","HTAN_Parent_Biospecimen_ID","Component",
           "File_Format","entityId","Run_ID"
    FROM HTAN_2.HTAN."_10XVISIUM_SPATIALTRANSCRIPTOMICS_AUXILIARYFILES_METADATA_CURRENT"
    WHERE "Run_ID" ILIKE '%HT264P1-S1H2Fc2U1Z1Bs1-H2Bs2-Test%'

    /* ------------------- scRNA-seq Level 1 ------------------- */
    UNION ALL
    SELECT "Filename",
           "HTAN_Parent_Biospecimen_ID",
           "Component",
           "File_Format",
           "entityId",
           NULL AS "Run_ID"
    FROM HTAN_2.HTAN."SCRNASEQ_LEVEL1_METADATA_CURRENT"
    WHERE "Filename" ILIKE '%HT264P1-S1H2%'

    /* ------------------- scRNA-seq Level 2 ------------------- */
    UNION ALL
    SELECT "Filename",
           NULL              AS "HTAN_Parent_Biospecimen_ID",
           "Component",
           "File_Format",
           "entityId",
           NULL              AS "Run_ID"
    FROM HTAN_2.HTAN."SCRNASEQ_LEVEL2_METADATA_CURRENT"
    WHERE "Filename" ILIKE '%HT264P1-S1H2%'

    /* ------------------- scRNA-seq Level 3 ------------------- */
    UNION ALL
    SELECT "Filename",
           NULL              AS "HTAN_Parent_Biospecimen_ID",
           "Component",
           "File_Format",
           "entityId",
           NULL              AS "Run_ID"
    FROM HTAN_2.HTAN."SCRNASEQ_LEVEL3_METADATA_CURRENT"
    WHERE  "Filename"               ILIKE '%HT264P1-S1H2%'
       OR "HTAN_Parent_Data_File_ID" ILIKE '%HT264P1-S1H2%'

    /* ------------------- scRNA-seq Level 4 ------------------- */
    UNION ALL
    SELECT "Filename",
           NULL              AS "HTAN_Parent_Biospecimen_ID",
           "Component",
           "File_Format",
           "entityId",
           NULL              AS "Run_ID"
    FROM HTAN_2.HTAN."SCRNASEQ_LEVEL4_METADATA_CURRENT"
    WHERE  "Filename"               ILIKE '%HT264P1-S1H2%'
       OR "HTAN_Parent_Data_File_ID" ILIKE '%HT264P1-S1H2%'
) AS merged
ORDER BY "Component", "Filename";