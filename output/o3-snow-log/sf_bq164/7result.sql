/* Consolidate any spatial-transcriptomics and scRNA-seq metadata records
   whose file names contain the fragment “HT264P1”.  Results are returned
   with a unified column set and are tagged with the requested run ID.   */

SELECT
       "Filename",
       "HTAN Parent Biospecimen ID",
       "Component",
       "File Format",
       "entityId",
       "Run ID"
FROM (

    /* ─────────── 1.  scRNA-seq  Level-4 metadata ─────────── */
    SELECT
           "Filename",
           "HTAN_Parent_Data_File_ID"          AS "HTAN Parent Biospecimen ID",
           "Component",
           "File_Format"                       AS "File Format",
           "entityId",
           'HT264P1-S1H2Fc2U1Z1Bs1-H2Bs2-Test' AS "Run ID"
    FROM   HTAN_2.HTAN."SCRNASEQ_LEVEL4_METADATA_CURRENT"
    WHERE  "Filename" ILIKE '%HT264P1%'

    UNION ALL

    /* ─────────── 2.  scRNA-seq  Level-2 metadata ─────────── */
    SELECT
           "Filename",
           "HTAN_Parent_Data_File_ID",
           "Component",
           "File_Format",
           "entityId",
           'HT264P1-S1H2Fc2U1Z1Bs1-H2Bs2-Test'
    FROM   HTAN_2.HTAN."SCRNASEQ_LEVEL2_METADATA_CURRENT"
    WHERE  "Filename" ILIKE '%HT264P1%'

    UNION ALL

    /* ─────────── 3.  Provenance / auxiliary (ID_PROVENANCE) ─────────── */
    SELECT
           "Filename",
           "HTAN_Parent_Data_File_ID",
           "Component",
           NULL                                AS "File Format",
           "entityId",
           'HT264P1-S1H2Fc2U1Z1Bs1-H2Bs2-Test'
    FROM   HTAN_2.HTAN."ID_PROVENANCE_CURRENT"
    WHERE  "Filename" ILIKE '%HT264P1%'

    UNION ALL

    /* ─────────── 4.  HTAPP scRNA-seq Level-4 (Biospecimen-based) ─────────── */
    SELECT
           "Source_filename"                   AS "Filename",
           "Biospecimen"                       AS "HTAN Parent Biospecimen ID",
           'ScRNA-seqLevel4'                   AS "Component",
           NULL                                AS "File Format",
           "Source_entityId"                   AS "entityId",
           'HT264P1-S1H2Fc2U1Z1Bs1-H2Bs2-Test'
    FROM   HTAN_2.HTAN."SCRNASEQ_HTAPP_LEVEL4_CURRENT"
    WHERE  "Source_filename" ILIKE '%HT264P1%'

    UNION ALL

    /* ─────────── 5.  Duke MIBI imaging Level-4 (spatial) ─────────── */
    SELECT
           "Source_filename",
           "HTAN_Biospecimen_ID",
           'ImagingLevel4_DukeMIBI'            AS "Component",
           NULL                                AS "File Format",
           "Source_entityId",
           'HT264P1-S1H2Fc2U1Z1Bs1-H2Bs2-Test'
    FROM   HTAN_2.HTAN."IMAGING_LEVEL4_DUKE_MIBI_CURRENT"
    WHERE  "Source_filename" ILIKE '%HT264P1%'

    UNION ALL

    /* ─────────── 6.  MERFISH imaging Level-4 (spatial) ─────────── */
    SELECT
           "Source_filename",
           "HTAN_Biospecimen_ID",
           'ImagingLevel4_MERFISH'             AS "Component",
           NULL                                AS "File Format",
           "Source_entityId",
           'HT264P1-S1H2Fc2U1Z1Bs1-H2Bs2-Test'
    FROM   HTAN_2.HTAN."IMAGING_LEVEL4_HTAPP_MERFISH_CURRENT"
    WHERE  "Source_filename" ILIKE '%HT264P1%'

    UNION ALL

    /* ─────────── 7.  Other assay auxiliary files ─────────── */
    SELECT
           "Filename",
           "HTAN_Parent_Biospecimen_ID",
           "Component",
           "File_Format",
           "entityId",
           'HT264P1-S1H2Fc2U1Z1Bs1-H2Bs2-Test'
    FROM   HTAN_2.HTAN."OTHER_ASSAY_METADATA_CURRENT"
    WHERE  "Filename" ILIKE '%HT264P1%'

) AS combined
ORDER BY "Filename" ASC;