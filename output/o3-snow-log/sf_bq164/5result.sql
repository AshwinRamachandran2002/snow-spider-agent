/*  Consolidate metadata for run-ID  HT264P1-S1H2Fc2U1Z1Bs1-H2Bs2-Test
    across spatial-transcriptomics and scRNA-seq datasets (Levels 1-4
    plus auxiliary provenance files).                                            */

SELECT
       "Filename",
       "HTAN Parent Biospecimen ID",
       "Component",
       "File Format",
       "Entity ID",
       'HT264P1-S1H2Fc2U1Z1Bs1-H2Bs2-Test'  AS "Run ID"
FROM (
        /* scRNA-seq Level-4 metadata ---------------------------------------- */
        SELECT
               "Filename",
               "HTAN_Parent_Data_File_ID"      AS "HTAN Parent Biospecimen ID",
               "Component",
               "File_Format"                   AS "File Format",
               "entityId"                      AS "Entity ID"
        FROM   HTAN_2.HTAN.SCRNASEQ_LEVEL4_METADATA_CURRENT
        
        UNION ALL
        
        /* scRNA-seq Level-2 metadata ---------------------------------------- */
        SELECT
               "Filename",
               "HTAN_Parent_Data_File_ID",
               "Component",
               "File_Format",
               "entityId"
        FROM   HTAN_2.HTAN.SCRNASEQ_LEVEL2_METADATA_CURRENT
        
        UNION ALL
        
        /* Level-4 auxiliary provenance -------------------------------------- */
        SELECT
               "Filename",
               "HTAN_Parent_Data_File_ID",
               "Component",
               NULL                            AS "File Format",
               "entityId"
        FROM   HTAN_2.HTAN.ID_PROVENANCE_CURRENT
        
        UNION ALL
        
        /* Spatial-transcriptomics (MERFISH) Level-4 ------------------------- */
        SELECT
               "Source_filename"               AS "Filename",
               "HTAN_Biospecimen_ID"           AS "HTAN Parent Biospecimen ID",
               NULL                            AS "Component",
               NULL                            AS "File Format",
               "Source_entityId"               AS "Entity ID"
        FROM   HTAN_2.HTAN.IMAGING_LEVEL4_HTAPP_MERFISH_CURRENT
        
        UNION ALL
        
        /* scRNA-seq HTAPP Level-4 counts ------------------------------------ */
        SELECT
               "Source_filename"               AS "Filename",
               "Biospecimen"                   AS "HTAN Parent Biospecimen ID",
               NULL                            AS "Component",
               NULL                            AS "File Format",
               "Source_entityId"               AS "Entity ID"
        FROM   HTAN_2.HTAN.SCRNASEQ_HTAPP_LEVEL4_CURRENT
     ) AS combined
WHERE  "Filename"                ILIKE '%HT264P1-S1H2Fc2U1Z1Bs1-H2Bs2-Test%'
   OR  "HTAN Parent Biospecimen ID" ILIKE '%HT264P1-S1H2Fc2U1Z1Bs1-H2Bs2-Test%'
   OR  "Component"               ILIKE '%HT264P1-S1H2Fc2U1Z1Bs1-H2Bs2-Test%'
   OR  "File Format"             ILIKE '%HT264P1-S1H2Fc2U1Z1Bs1-H2Bs2-Test%'
   OR  "Entity ID"               ILIKE '%HT264P1-S1H2Fc2U1Z1Bs1-H2Bs2-Test%';