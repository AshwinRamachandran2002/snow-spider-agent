SELECT
       "Filename",
       "HTAN Parent Biospecimen ID",
       "Component",
       "File Format",
       "Entity ID",
       "Run ID"
FROM (
        /* 10x Visium Spatial‑Tx – Level 1 */
        SELECT  "Filename",
                "HTAN_Parent_Biospecimen_ID"  AS "HTAN Parent Biospecimen ID",
                "Component",
                "File_Format"                 AS "File Format",
                "entityId"                    AS "Entity ID",
                "Run_ID"                      AS "Run ID"
        FROM    "HTAN_2"."HTAN"."_10XVISIUM_SPATIALTRANSCRIPTOMICS_SCRNASEQ_LEVEL1_METADATA_CURRENT"

        UNION ALL
        /* 10x Visium Spatial‑Tx – Level 2 */
        SELECT  "Filename",
                "HTAN_Parent_Biospecimen_ID",
                "Component",
                "File_Format",
                "entityId",
                "Run_ID"
        FROM    "HTAN_2"."HTAN"."_10XVISIUM_SPATIALTRANSCRIPTOMICS_SCRNASEQ_LEVEL2_METADATA_CURRENT"

        UNION ALL
        /* 10x Visium Spatial‑Tx – Level 3 */
        SELECT  "Filename",
                "HTAN_Parent_Biospecimen_ID",
                "Component",
                "File_Format",
                "entityId",
                "Run_ID"
        FROM    "HTAN_2"."HTAN"."_10XVISIUM_SPATIALTRANSCRIPTOMICS_SCRNASEQ_LEVEL3_METADATA_CURRENT"

        UNION ALL
        /* 10x Visium Spatial‑Tx – Level 4 */
        SELECT  "Filename",
                "HTAN_Parent_Biospecimen_ID",
                "Component",
                "File_Format",
                "entityId",
                "Run_ID"
        FROM    "HTAN_2"."HTAN"."_10XVISIUM_SPATIALTRANSCRIPTOMICS_SCRNASEQ_LEVEL4_METADATA_CURRENT"

        UNION ALL
        /* 10x Visium Spatial‑Tx – Auxiliary files */
        SELECT  "Filename",
                "HTAN_Parent_Biospecimen_ID",
                "Component",
                "File_Format",
                "entityId",
                "Run_ID"
        FROM    "HTAN_2"."HTAN"."_10XVISIUM_SPATIALTRANSCRIPTOMICS_AUXILIARYFILES_METADATA_CURRENT"

        UNION ALL
        /* scRNA‑seq – Level 1 */
        SELECT  "Filename",
                "HTAN_Parent_Biospecimen_ID",
                "Component",
                "File_Format",
                "entityId",
                'N/A'                         AS "Run ID"
        FROM    "HTAN_2"."HTAN"."SCRNASEQ_LEVEL1_METADATA_CURRENT"

        UNION ALL
        /* scRNA‑seq – Level 2 */
        SELECT  "Filename",
                "HTAN_Parent_Data_File_ID"    AS "HTAN Parent Biospecimen ID",
                "Component",
                "File_Format",
                "entityId",
                'N/A'
        FROM    "HTAN_2"."HTAN"."SCRNASEQ_LEVEL2_METADATA_CURRENT"

        UNION ALL
        /* scRNA‑seq – Level 3 */
        SELECT  "Filename",
                "HTAN_Parent_Data_File_ID",
                "Component",
                "File_Format",
                "entityId",
                'N/A'
        FROM    "HTAN_2"."HTAN"."SCRNASEQ_LEVEL3_METADATA_CURRENT"

        UNION ALL
        /* scRNA‑seq – Level 4 */
        SELECT  "Filename",
                "HTAN_Parent_Data_File_ID",
                "Component",
                "File_Format",
                "entityId",
                'N/A'
        FROM    "HTAN_2"."HTAN"."SCRNASEQ_LEVEL4_METADATA_CURRENT"
) AS COMBINED
WHERE   "Run ID" = 'HT264P1-S1H2Fc2U1Z1Bs1-H2Bs2-Test'
     OR "Filename" LIKE '%HT264P1-S1H2Fc2U1Z1Bs1-H2Bs2-Test%'
ORDER BY "Component", "Filename";