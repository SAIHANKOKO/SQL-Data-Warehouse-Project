/*
===================================================================================================
Store Procedure : Load Silver Layer (Bronze -> Silver)
Script Purpose  : This store procedure performs the ETL (Extract, Transform & Load) process to
                  populate the 'silver' schema talbes from the 'bronze' schema tables.
				          It perform the following actions :
				         - Truncate the silver tables
				         - Insert cleaned and transformed data from bronze into silver tables
Parameters		  : NONE. This store procedure does not accept any parameter or return any values.
Use Example		  : EXEC silver.load_silver;
===================================================================================================
*/

CREATE OR ALTER PROCEDURE silver.load_silver AS
BEGIN 
	DECLARE @start_time DATETIME,@end_time DATETIME, @batch_start_time DATETIME, @batch_end_time DATETIME;
	BEGIN TRY
		SET @batch_start_time = GETDATE();
		PRINT '==========================';
		PRINT 'LOADING SILVER LAYER';
		PRINT '==========================';

		PRINT '--------------------------';
		PRINT 'LOADING TABLES FROM bronze.crm';
		PRINT '--------------------------';
	
		PRINT '>>Truncating Table :silver.crm_cust_info';
		SET @start_time = GETDATE();
		TRUNCATE TABLE silver.crm_cust_info;
		PRINT '>>Inserting Data Into :silver.crm_cust_info';
		INSERT INTO silver.crm_cust_info (
		cst_id,
		cst_key,
		cst_firstname,
		cst_lastname,
		cst_marital_status,
		cst_gndr,
		cst_create_date)

		SELECT 
		cst_id,
		cst_key,
		TRIM (cst_firstname) AS cst_firstname,                            --(Removing Unwanted spaces)--
		TRIM (cst_lastname) AS cst_lastname,	                          --(Removing Unwanted spaces)--				
		CASE WHEN UPPER(cst_marital_status) = 'S' THEN 'SINGLE'	          --(STANDARDIZING AND NORMALIZING DATA)--			
			 WHEN UPPER(cst_marital_status) = 'M' THEN 'MARRIED'
			 ELSE 'UNKNOWN'
		END AS cst_marital_status,
		CASE WHEN UPPER(cst_gndr) = 'F' THEN 'FEMALE'					  --(STANDARDIZING AND NORMALIZING DATA)--
			 WHEN UPPER(cst_gndr) = 'M' THEN 'MALE'
			 ELSE 'UNKNOWN'
		END AS cst_gndr,
		cst_create_date
																		  --(HANDLING NULLS & DUPLICATES IN PRIMARY KEY)--
		FROM(																			
			SELECT 
			*,
			ROW_NUMBER() OVER (PARTITION BY cst_id ORDER BY cst_create_date DESC) as FLAG
			FROM bronze.crm_cust_info
			WHERE cst_id IS NOT NULL
		)t WHERE FLAG = 1 ;

		SET @end_time = GETDATE();
		PRINT '>>Loading Duration :'+ CAST(DATEDIFF(MILLISECOND,@start_time,@end_time) AS NVARCHAR) + 'ms';
		PRINT '---------------------------------------------';
		------------------------------------------------------------------------------------

		PRINT '>>Truncating Table :silver.crm_prd_info ';
		SET @start_time = GETDATE();
		TRUNCATE TABLE silver.crm_prd_info ;
		PRINT '>>Inserting Data Into :silver.crm_prd_info ';
		INSERT INTO silver.crm_prd_info (
		prd_id,
		prd_key,
		cat_id,
		prd_key2,
		prd_nm,
		prd_cost,
		prd_line,
		prd_start_dt,
		prd_end_dt 
		)
		SELECT 
		prd_id,
		prd_key,
		REPLACE (SUBSTRING (prd_key,1,5),'-','_') AS cat_id,	--Extract category id
		SUBSTRING (prd_key,7,LEN(prd_key)) AS prd_key2,			--Extract product key
		prd_nm,
		ISNULL (prd_cost,0) AS prd_cost,						-- Handling NULLS 
		CASE UPPER(TRIM(prd_line))	
			 WHEN 'M' THEN 'Moutain'
			 WHEN 'R' THEN 'Road'
			 WHEN 'S' THEN 'Other Sales'
			 WHEN 'T' THEN 'Touring'
			 ELSE 'Unknown'
		END AS prd_line,										-- Mapping product line code to descriptive values 
		CAST (prd_start_dt AS DATE) as prd_start_dt ,			
		CAST (LEAD (prd_start_dt) OVER(PARTITION BY prd_key Order By prd_start_dt) - 1 AS DATE) as prd_end_dt	-- Calculate end date as one day before next start date
		FROM [bronze].[crm_prd_info];

		SET @end_time = GETDATE();
		PRINT '>>Loading Duration :'+ CAST(DATEDIFF(MILLISECOND,@start_time,@end_time) AS NVARCHAR) + 'ms';
		PRINT '---------------------------------------------';

		---------------------------------------------------------------------------
		PRINT '>>Truncating Table :silver.crm_sales_details';
		SET @start_time = GETDATE();
		TRUNCATE TABLE silver.crm_sales_details;
		PRINT '>>Inserting Data Into :silver.crm_sales_details';
		INSERT INTO silver.crm_sales_details (
			sls_ord_num,		
			sls_prd_key,		
			sls_cust_id,		
			sls_order_dt,		
			sls_ship_dt,			
			sls_due_dt,			
			sls_sales,			
			sls_quantity,		
			sls_price
		)		

		SELECT 
		sls_ord_num,
		sls_prd_key,
		sls_cust_id,
		CASE WHEN sls_order_dt <= 0 OR LEN(sls_order_dt) != 8 THEN NULL
			 ELSE CAST(CAST(sls_order_dt AS NVARCHAR) AS DATE)
		END AS sls_order_dt,

		CASE WHEN sls_ship_dt <= 0 OR LEN(sls_ship_dt) != 8 THEN NULL
			 ELSE CAST(CAST(sls_ship_dt AS NVARCHAR) AS DATE)
		END AS sls_ship_dt,

		CASE WHEN sls_due_dt <= 0 OR LEN(sls_due_dt) != 8 THEN NULL
			 ELSE CAST(CAST(sls_due_dt AS NVARCHAR) AS DATE)
		END AS sls_due_dt,

		CASE WHEN sls_sales IS NULL OR sls_sales <= 0 OR sls_sales != sls_quantity * ABS(sls_price)
			 THEN sls_quantity * ABS(sls_price)
			 ELSE sls_sales
		END AS sls_sales,

		sls_quantity,

		CASE WHEN sls_price IS NULL OR sls_price <= 0
			 THEN sls_sales / NULLIF(sls_quantity,0)
			 ELSE sls_price
		END AS sls_price

		FROM bronze.crm_sales_details;
		SET @end_time = GETDATE();
		PRINT '>>Loading Duration :'+ CAST(DATEDIFF(MILLISECOND,@start_time,@end_time) AS NVARCHAR) + 'ms';
		PRINT '---------------------------------------------';
		--------------------------------------------------------------------------------

		PRINT '---------------------------------------';
		PRINT 'LOADING TABLES FROM bronze.erp';
		PRINT '---------------------------------------';

		PRINT '>>Truncating Table :silver.erp_cust_az12 '
		SET @start_time = GETDATE();
		TRUNCATE TABLE silver.erp_cust_az12;
		PRINT '>>Inserting Data Into :silver.erp_cust_az12 '
		INSERT INTO silver.erp_cust_az12(
		cid,
		bdate,
		gen
		)
		SELECT 
		CASE WHEN cid LIKE 'NAS%' THEN SUBSTRING (cid,4,LEN(cid)) --Remove 'NAS' prefix if have
			 ELSE cid
		END AS cid,
		CASE WHEN bdate > GETDATE() THEN NULL    -- Set future birthdate to NULL
			 ELSE bdate
		END AS bdate,

		CASE WHEN UPPER(gen) lIKE '%F%' THEN 'FEMALE' 
			 WHEN UPPER(gen) Like '%M%' THEN 'MALE'
			 ELSE 'UNKNOWN'
		END AS gen										-- Handling unknown cases and normalize gender values
		FROM bronze.erp_cust_az12;
		SET @end_time = GETDATE();
		PRINT '>>Loading Duration :'+ CAST(DATEDIFF(MILLISECOND,@start_time,@end_time) AS NVARCHAR) + 'ms';
		PRINT '---------------------------------------------';
		----------------------------------------------------------------------------------
		PRINT '>>Truncating Table :silver.erp_loc_a101 '
		SET @start_time = GETDATE();
		TRUNCATE TABLE silver.erp_loc_a101;
		PRINT '>>Inserting Data Into :silver.erp_loc_a101 '
		INSERT INTO silver.erp_loc_a101 (
		cid,
		cntry
		)

		SELECT
		REPLACE(cid,'-','') AS cid,   
		CASE WHEN TRIM (cntry) = 'DE' THEN 'Germany'
			 WHEN TRIM (cntry) IN ('US','USA') THEN 'United States'
			 WHEN TRIM (cntry) = '' OR TRIM (cntry) IS NULL THEN 'UNKNOWN'
			 ELSE TRIM (cntry)
		END AS cntry					-- Normalize country names
		FROM bronze.erp_loc_a101;
		SET @end_time = GETDATE();
		PRINT '>>Loading Duration :'+ CAST(DATEDIFF(MILLISECOND,@start_time,@end_time) AS NVARCHAR) + 'ms';
		PRINT '---------------------------------------------';
		----------------------------------------------------------------------------------
		PRINT '>>Truncating Table :silver.erp_px_cat_g1v2'
		SET @start_time = GETDATE();
		TRUNCATE TABLE silver.erp_px_cat_g1v2;
		PRINT '>>Inserting Data Into :silver.erp_px_cat_g1v2'
		INSERT INTO silver.erp_px_cat_g1v2 (
			id,					
			cat,					
			subcat,				
			maintenance	
		)

		SELECT 
		id,
		cat,
		subcat,
		maintenance
		FROM bronze.erp_px_cat_g1v2;
		SET @end_time = GETDATE();
		PRINT '>>Loading Duration :'+ CAST(DATEDIFF(MILLISECOND,@start_time,@end_time) AS NVARCHAR) + 'ms';
		PRINT '---------------------------------------------';

		SET @batch_end_time = GETDATE ();
		PRINT '====================================';
		PRINT 'LOADING SILVER LAYER IS COMPLETED';
		PRINT 'TOTAL LOADING DURATION :' + CAST(DATEDIFF(MILLISECOND,@batch_start_time,@batch_end_time) AS NVARCHAR) + 'ms';
		PRINT '====================================';
	
	END TRY
	BEGIN CATCH
		PRINT '=================================================';
		PRINT 'ERROR OCCURED DURING LOADING SILVER LAYER';
		PRINT 'ERROR MESSAGE' + ERROR_MESSAGE();
		PRINT 'ERROR MESSAGE' + CAST(ERROR_NUMBER() AS NVARCHAR);
		PRINT 'ERROR MESSAGE' + CAST(ERROR_STATE() AS NVARCHAR);
		PRINT '=================================================';
	END CATCH	
END
