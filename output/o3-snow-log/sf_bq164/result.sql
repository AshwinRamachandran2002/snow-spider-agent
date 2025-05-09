WITH combined
     ( "Filename",
       "HTAN Parent Biospecimen ID",
       "Component",
       "File_Format",
       "Entity ID")
AS
(
    /* scRNA-seq Level-2 metadata */
    SELECT
        "Filename",
        "HTAN_Parent_Data_File_ID"               AS "HTAN Parent Biospecimen ID",
        "Component",
        "File_Format",
        "entityId"                               AS "Entity ID"
    FROM   HTAN_2.HTAN."SCRNASEQ_LEVEL2_METADATA_CURRENT"

    UNION ALL

    /* scRNA-seq Level-4 metadata */
    SELECT
        "Filename",
        "HTAN_Parent_Data_File_ID",
        "Component",
        "File_Format",
        "entityId"
    FROM   HTAN_2.HTAN."SCRNASEQ_LEVEL4_METADATA_CURRENT"

    UNION ALL

    /* scRNA-seq provenance table (contains Level-1 & Level-4 auxiliary objects) */
    SELECT
        "Filename",
        "HTAN_Parent_Data_File_ID",
        "Component",
        NULL                                     AS "File_Format",
        "entityId"
    FROM   HTAN_2.HTAN."ID_PROVENANCE_CURRENT"

    UNION ALL

    /* Spatial-transcriptomics (MERFISH) Level-4 metadata */
    SELECT
        "Source_filename"                        AS "Filename",
        "HTAN_Biospecimen_ID"                    AS "HTAN Parent Biospecimen ID",
        'ImagingLevel4-MERFISH'                  AS "Component",
        NULL                                     AS "File_Format",
        "Source_entityId"                        AS "Entity ID"
    FROM   HTAN_2.HTAN."IMAGING_LEVEL4_HTAPP_MERFISH_CURRENT"

    UNION ALL

    /* Other Assay auxiliary files */
    SELECT
        "Filename",
        "HTAN_Parent_Biospecimen_ID",
        "Component",
        "File_Format",
        "entityId"
    FROM   HTAN_2.HTAN."OTHER_ASSAY_METADATA_CURRENT"

    UNION ALL

    /* Accessory manifest (no filename; included for completeness) */
    SELECT
        NULL                                     AS "Filename",
        "HTAN_Parent_Biospecimen_ID",
        "Component",
        NULL                                     AS "File_Format",
        "entityId"
    FROM   HTAN_2.HTAN."ACCESSORY_MANIFEST_CURRENT"
)

SELECT DISTINCT
       "Filename",
       "HTAN Parent Biospecimen ID",
       "Component",
       "File_Format",
       "Entity ID",
       'HT264P1-S1H2Fc2U1Z1Bs1-H2Bs2-Test'      AS "Run ID"
FROM   combined
WHERE  COALESCE("Filename", '') ILIKE '%HT264P1%'
    OR COALESCE("HTAN Parent Biospecimen ID", '') ILIKE '%HT264P1%'
ORDER  BY "Component" NULLS LAST,
          "Filename"   NULLS LAST;