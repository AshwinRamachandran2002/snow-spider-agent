/* Consolidate spatial-transcriptomics and scRNA-seq metadata records that
   mention the run-identifier ‘HT264P1-S1H2Fc2U1Z1Bs1-H2Bs2-Test’            */

SELECT
       "Filename",
       "HTAN Parent Biospecimen ID",
       "Component",
       "File Format",
       "Entity ID",
       'HT264P1-S1H2Fc2U1Z1Bs1-H2Bs2-Test' AS "Run ID"
FROM (
        /* ─────────  scRNA-seq  Level-2  ───────── */
        SELECT  "Filename",
                "HTAN_Parent_Data_File_ID"                    AS "HTAN Parent Biospecimen ID",
                "Component",
                "File_Format"                                 AS "File Format",
                "entityId"                                    AS "Entity ID"
        FROM    HTAN_2.HTAN."SCRNASEQ_LEVEL2_METADATA_CURRENT"
        WHERE   "Filename" ILIKE '%HT264P1-S1H2Fc2U1Z1Bs1-H2Bs2-Test%'

        UNION ALL

        /* ─────────  scRNA-seq  Level-4 (generic metadata)  ───────── */
        SELECT  "Filename",
                "HTAN_Parent_Data_File_ID"                    AS "HTAN Parent Biospecimen ID",
                "Component",
                "File_Format"                                 AS "File Format",
                "entityId"                                    AS "Entity ID"
        FROM    HTAN_2.HTAN."SCRNASEQ_LEVEL4_METADATA_CURRENT"
        WHERE   "Filename" ILIKE '%HT264P1-S1H2Fc2U1Z1Bs1-H2Bs2-Test%'

        UNION ALL

        /* ─────────  scRNA-seq  Level-4 (HTAPP single-cell table)  ───────── */
        SELECT  "Source_filename"                             AS "Filename",
                "Biospecimen"                                 AS "HTAN Parent Biospecimen ID",
                'ScRNA-seqLevel4'                             AS "Component",
                NULL                                          AS "File Format",
                "Source_entityId"                            AS "Entity ID"
        FROM    HTAN_2.HTAN."SCRNASEQ_HTAPP_LEVEL4_CURRENT"
        WHERE   "Source_filename" ILIKE '%HT264P1-S1H2Fc2U1Z1Bs1-H2Bs2-Test%'

        UNION ALL

        /* ─────────  ID–Provenance bridge (links all levels)  ───────── */
        SELECT  "Filename",
                "HTAN_Parent_Data_File_ID"                    AS "HTAN Parent Biospecimen ID",
                "Component",
                NULL                                          AS "File Format",
                "entityId"                                    AS "Entity ID"
        FROM    HTAN_2.HTAN."ID_PROVENANCE_CURRENT"
        WHERE   "Filename" ILIKE '%HT264P1-S1H2Fc2U1Z1Bs1-H2Bs2-Test%'

        UNION ALL

        /* ─────────  Spatial-transcriptomics  (MERFISH)  ───────── */
        SELECT  "Source_filename"                             AS "Filename",
                "HTAN_Biospecimen_ID"                         AS "HTAN Parent Biospecimen ID",
                'SpatialTranscriptomics'                      AS "Component",
                NULL                                          AS "File Format",
                "Source_entityId"                             AS "Entity ID"
        FROM    HTAN_2.HTAN."IMAGING_LEVEL4_HTAPP_MERFISH_CURRENT"
        WHERE   "Source_filename" ILIKE '%HT264P1-S1H2Fc2U1Z1Bs1-H2Bs2-Test%'

        UNION ALL

        /* ─────────  Imaging  Level-4 (Duke MIBI)  ───────── */
        SELECT  "Source_filename"                             AS "Filename",
                "HTAN_Biospecimen_ID"                         AS "HTAN Parent Biospecimen ID",
                'ImagingLevel4'                               AS "Component",
                NULL                                          AS "File Format",
                "Source_entityId"                             AS "Entity ID"
        FROM    HTAN_2.HTAN."IMAGING_LEVEL4_DUKE_MIBI_CURRENT"
        WHERE   "Source_filename" ILIKE '%HT264P1-S1H2Fc2U1Z1Bs1-H2Bs2-Test%'

        UNION ALL

        /* ─────────  Auxiliary / Other-assay files  ───────── */
        SELECT  "Filename",
                "HTAN_Parent_Biospecimen_ID"                  AS "HTAN Parent Biospecimen ID",
                "Component",
                "File_Format"                                 AS "File Format",
                "entityId"                                    AS "Entity ID"
        FROM    HTAN_2.HTAN."OTHER_ASSAY_METADATA_CURRENT"
        WHERE   "Filename" ILIKE '%HT264P1-S1H2Fc2U1Z1Bs1-H2Bs2-Test%'
     ) AS combined;