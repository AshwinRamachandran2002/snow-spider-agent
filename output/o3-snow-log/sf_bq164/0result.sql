/* -------------------------------------------------------------------------
   Consolidate spatial-transcriptomics and scRNA-seq metadata (Levels 1–4,
   auxiliary files) that reference the run-ID
   ‘HT264P1-S1H2Fc2U1Z1Bs1-H2Bs2-Test’.
   -------------------------------------------------------------------------
   Returned columns:
     1. Filename
     2. HTAN Parent Biospecimen ID
     3. Component
     4. File Format
     5. Entity ID
     6. Run ID  (constant string so downstream users know the filter used)
   ------------------------------------------------------------------------- */
SELECT
    t."Filename",
    t."HTAN Parent Biospecimen ID",
    t."Component",
    t."File Format",
    t."Entity ID",
    t."Run ID"
FROM (
    /* ---------- scRNA-seq Level 2 ---------- */
    SELECT
        "Filename",
        "HTAN_Parent_Data_File_ID"               AS "HTAN Parent Biospecimen ID",
        "Component",
        "File_Format"                            AS "File Format",
        "entityId"                               AS "Entity ID",
        'HT264P1-S1H2Fc2U1Z1Bs1-H2Bs2-Test'      AS "Run ID"
    FROM HTAN_2.HTAN.SCRNASEQ_LEVEL2_METADATA_CURRENT

    UNION ALL

    /* ---------- scRNA-seq Level 4 (metadata file) ---------- */
    SELECT
        "Filename",
        "HTAN_Parent_Data_File_ID"               AS "HTAN Parent Biospecimen ID",
        "Component",
        "File_Format"                            AS "File Format",
        "entityId"                               AS "Entity ID",
        'HT264P1-S1H2Fc2U1Z1Bs1-H2Bs2-Test'      AS "Run ID"
    FROM HTAN_2.HTAN.SCRNASEQ_LEVEL4_METADATA_CURRENT

    UNION ALL

    /* ---------- ID Provenance (auxiliary for Level 4 objects) ---------- */
    SELECT
        "Filename",
        "HTAN_Parent_Data_File_ID"               AS "HTAN Parent Biospecimen ID",
        "Component",
        NULL                                     AS "File Format",
        "entityId"                               AS "Entity ID",
        'HT264P1-S1H2Fc2U1Z1Bs1-H2Bs2-Test'      AS "Run ID"
    FROM HTAN_2.HTAN.ID_PROVENANCE_CURRENT

    UNION ALL

    /* ---------- scRNA-seq Level 4 (HTAPP, cell-matrix TSVs) ---------- */
    SELECT
        "Source_filename"                        AS "Filename",
        "Biospecimen"                            AS "HTAN Parent Biospecimen ID",
        'ScRNA-seqLevel4'                        AS "Component",
        SPLIT_PART("Source_filename",'.',-1)     AS "File Format",
        "Source_entityId"                        AS "Entity ID",
        'HT264P1-S1H2Fc2U1Z1Bs1-H2Bs2-Test'      AS "Run ID"
    FROM HTAN_2.HTAN.SCRNASEQ_HTAPP_LEVEL4_CURRENT

    UNION ALL

    /* ---------- Spatial-Tx Level 4 (MERFISH) ---------- */
    SELECT
        "Source_filename"                        AS "Filename",
        "HTAN_Biospecimen_ID"                    AS "HTAN Parent Biospecimen ID",
        'SpatialTxLevel4'                        AS "Component",
        SPLIT_PART("Source_filename",'.',-1)     AS "File Format",
        "Source_entityId"                        AS "Entity ID",
        'HT264P1-S1H2Fc2U1Z1Bs1-H2Bs2-Test'      AS "Run ID"
    FROM HTAN_2.HTAN.IMAGING_LEVEL4_HTAPP_MERFISH_CURRENT

    UNION ALL

    /* ---------- Accessory Manifest ---------- */
    SELECT
        "Id"                                     AS "Filename",
        "HTAN_Parent_Biospecimen_ID"             AS "HTAN Parent Biospecimen ID",
        "Component",
        NULL                                     AS "File Format",
        "entityId"                               AS "Entity ID",
        'HT264P1-S1H2Fc2U1Z1Bs1-H2Bs2-Test'      AS "Run ID"
    FROM HTAN_2.HTAN.ACCESSORY_MANIFEST_CURRENT

    UNION ALL

    /* ---------- Other Assay files (auxiliary) ---------- */
    SELECT
        "Filename",
        "HTAN_Parent_Biospecimen_ID"             AS "HTAN Parent Biospecimen ID",
        "Component",
        "File_Format"                            AS "File Format",
        "entityId"                               AS "Entity ID",
        'HT264P1-S1H2Fc2U1Z1Bs1-H2Bs2-Test'      AS "Run ID"
    FROM HTAN_2.HTAN.OTHER_ASSAY_METADATA_CURRENT
) t
WHERE t."Filename" ILIKE '%HT264P1-S1H2Fc2U1Z1Bs1-H2Bs2-Test%';