/* Consolidate spatial-/scRNA-seq metadata (Levels 1–4 + auxiliary files)
   for run-ID “HT264P1-S1H2Fc2U1Z1Bs1-H2Bs2-Test”                          */

SELECT *
FROM (
    /* ───────────────  scRNA-seq Level-2  ─────────────── */
    SELECT
        "Filename",
        NULL                                   AS "HTAN Parent Biospecimen ID",
        "Component",
        "File_Format"                         AS "File Format",
        "entityId",
        'HT264P1-S1H2Fc2U1Z1Bs1-H2Bs2-Test'   AS "Run ID"
    FROM   HTAN_2.HTAN.SCRNASEQ_LEVEL2_METADATA_CURRENT
    WHERE  "Filename" ILIKE '%HT264P1-S1H2Fc2U1Z1Bs1-H2Bs2-Test%'

    UNION ALL
    /* ───────────────  scRNA-seq Level-4 (metadata)  ─────────────── */
    SELECT
        "Filename",
        NULL                                   AS "HTAN Parent Biospecimen ID",
        "Component",
        "File_Format"                         AS "File Format",
        "entityId",
        'HT264P1-S1H2Fc2U1Z1Bs1-H2Bs2-Test'   AS "Run ID"
    FROM   HTAN_2.HTAN.SCRNASEQ_LEVEL4_METADATA_CURRENT
    WHERE  "Filename" ILIKE '%HT264P1-S1H2Fc2U1Z1Bs1-H2Bs2-Test%'

    UNION ALL
    /* ───────────────  Provenance / auxiliary  ─────────────── */
    SELECT
        "Filename",
        NULL                                   AS "HTAN Parent Biospecimen ID",
        "Component",
        NULL                                   AS "File Format",
        "entityId",
        'HT264P1-S1H2Fc2U1Z1Bs1-H2Bs2-Test'   AS "Run ID"
    FROM   HTAN_2.HTAN.ID_PROVENANCE_CURRENT
    WHERE  "Filename" ILIKE '%HT264P1-S1H2Fc2U1Z1Bs1-H2Bs2-Test%'

    UNION ALL
    /* ───────────────  HTAPP Level-4 counts  ─────────────── */
    SELECT
        "Source_filename"                      AS "Filename",
        "Biospecimen"                          AS "HTAN Parent Biospecimen ID",
        'ScRNA-seqLevel4'                      AS "Component",
        NULL                                   AS "File Format",
        "Source_entityId"                      AS "entityId",
        'HT264P1-S1H2Fc2U1Z1Bs1-H2Bs2-Test'   AS "Run ID"
    FROM   HTAN_2.HTAN.SCRNASEQ_HTAPP_LEVEL4_CURRENT
    WHERE  "Source_filename" ILIKE '%HT264P1-S1H2Fc2U1Z1Bs1-H2Bs2-Test%'

    UNION ALL
    /* ───────────────  Other-assay auxiliary files  ─────────────── */
    SELECT
        "Filename",
        "HTAN_Parent_Biospecimen_ID"          AS "HTAN Parent Biospecimen ID",
        "Component",
        "File_Format"                         AS "File Format",
        "entityId",
        'HT264P1-S1H2Fc2U1Z1Bs1-H2Bs2-Test'   AS "Run ID"
    FROM   HTAN_2.HTAN.OTHER_ASSAY_METADATA_CURRENT
    WHERE  "Filename" ILIKE '%HT264P1-S1H2Fc2U1Z1Bs1-H2Bs2-Test%'

    UNION ALL
    /* ───────────────  Imaging Level-4 (MIBI)  ─────────────── */
    SELECT
        "Source_filename"                      AS "Filename",
        "HTAN_Biospecimen_ID"                  AS "HTAN Parent Biospecimen ID",
        'ImagingLevel4MIBI'                    AS "Component",
        NULL                                   AS "File Format",
        "Source_entityId"                      AS "entityId",
        'HT264P1-S1H2Fc2U1Z1Bs1-H2Bs2-Test'   AS "Run ID"
    FROM   HTAN_2.HTAN.IMAGING_LEVEL4_DUKE_MIBI_CURRENT
    WHERE  "Source_filename" ILIKE '%HT264P1-S1H2Fc2U1Z1Bs1-H2Bs2-Test%'

    UNION ALL
    /* ───────────────  Imaging Level-4 (MERFISH)  ─────────────── */
    SELECT
        "Source_filename"                      AS "Filename",
        "HTAN_Biospecimen_ID"                  AS "HTAN Parent Biospecimen ID",
        'ImagingLevel4MERFISH'                 AS "Component",
        NULL                                   AS "File Format",
        "Source_entityId"                      AS "entityId",
        'HT264P1-S1H2Fc2U1Z1Bs1-H2Bs2-Test'   AS "Run ID"
    FROM   HTAN_2.HTAN.IMAGING_LEVEL4_HTAPP_MERFISH_CURRENT
    WHERE  "Source_filename" ILIKE '%HT264P1-S1H2Fc2U1Z1Bs1-H2Bs2-Test%'
) AS combined
ORDER BY "Filename";