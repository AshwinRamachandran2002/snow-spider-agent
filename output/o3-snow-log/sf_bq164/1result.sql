SELECT
       "Filename",
       "HTAN_Parent_Biospecimen_ID",
       "Component",
       "File_Format",
       "entityId",
       'HT264P1-S1H2Fc2U1Z1Bs1-H2Bs2-Test' AS "Run_ID"
FROM (
    /* scRNA-seq – Level-4 metadata                               */
    SELECT
        "Filename",
        "HTAN_Parent_Data_File_ID"                        AS "HTAN_Parent_Biospecimen_ID",
        "Component",
        "File_Format",
        "entityId"
    FROM HTAN_2.HTAN.SCRNASEQ_LEVEL4_METADATA_CURRENT

    UNION ALL

    /* scRNA-seq – Level-2 metadata                               */
    SELECT
        "Filename",
        "HTAN_Parent_Data_File_ID"                        AS "HTAN_Parent_Biospecimen_ID",
        "Component",
        "File_Format",
        "entityId"
    FROM HTAN_2.HTAN.SCRNASEQ_LEVEL2_METADATA_CURRENT

    UNION ALL

    /* scRNA-seq – auxiliary provenance files                     */
    SELECT
        "Filename",
        "HTAN_Parent_Data_File_ID"                        AS "HTAN_Parent_Biospecimen_ID",
        "Component",
        NULL                                              AS "File_Format",
        "entityId"
    FROM HTAN_2.HTAN.ID_PROVENANCE_CURRENT

    UNION ALL

    /* scRNA-seq – HTAPP Level-4 summary table                    */
    SELECT
        "Source_filename"                                 AS "Filename",
        "Biospecimen"                                     AS "HTAN_Parent_Biospecimen_ID",
        'ScRNA-seqLevel4'                                 AS "Component",
        NULL                                              AS "File_Format",
        "Source_entityId"                                 AS "entityId"
    FROM HTAN_2.HTAN.SCRNASEQ_HTAPP_LEVEL4_CURRENT

    UNION ALL

    /* Spatial-transcriptomics – MERFISH Level-4                  */
    SELECT
        "Source_filename"                                 AS "Filename",
        "HTAN_Biospecimen_ID"                             AS "HTAN_Parent_Biospecimen_ID",
        'ImagingLevel4_HTAPP_MERFISH'                     AS "Component",
        NULL                                              AS "File_Format",
        "Source_entityId"                                 AS "entityId"
    FROM HTAN_2.HTAN.IMAGING_LEVEL4_HTAPP_MERFISH_CURRENT

    UNION ALL

    /* Spatial-transcriptomics – MIBI Level-4                     */
    SELECT
        "Source_filename"                                 AS "Filename",
        "HTAN_Biospecimen_ID"                             AS "HTAN_Parent_Biospecimen_ID",
        'ImagingLevel4_DUKE_MIBI'                         AS "Component",
        NULL                                              AS "File_Format",
        "Source_entityId"                                 AS "entityId"
    FROM HTAN_2.HTAN.IMAGING_LEVEL4_DUKE_MIBI_CURRENT

    UNION ALL

    /* Accessory manifest (auxiliary metadata)                    */
    SELECT
        NULL                                              AS "Filename",
        "HTAN_Parent_Biospecimen_ID",
        "Component",
        NULL                                              AS "File_Format",
        "entityId"
    FROM HTAN_2.HTAN.ACCESSORY_MANIFEST_CURRENT
) AS merged_data
WHERE
      "Filename"                ILIKE '%HT264%'
   OR "HTAN_Parent_Biospecimen_ID" ILIKE '%HT264%';