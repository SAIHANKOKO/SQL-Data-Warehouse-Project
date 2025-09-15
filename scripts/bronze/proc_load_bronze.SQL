/*
===================================================================================================
Store Procedure : Load Bronze Layer (Source -> Bronze)
Script Purpose  : This store procedure loads data into bronze schema from external csv files.
				 It perform the following actions :
				 - Truncate the bronze tables before loading the data
				 - Use 'BULK INSERT' command to load the data from csv files and insert to bronze tables.

Parameters		: NONE. This store procedure does not accept any parameter or return any values.
Use Expame		: EXEC bronze.load_bronze;
===================================================================================================
*/

CREATE OR ALTER PROCEDURE bronze.load_bronze AS
BEGIN
	DECLARE @start_time DATETIME,@end_time DATETIME, @batch_start_time DATETIME, @batch_end_time DATETIME;
	BEGIN TRY
		SET @batch_start_time = GETDATE ();
		PRINT '==========================';
		PRINT 'LOADING BRONZE LAYER';
		PRINT '==========================';
	
		PRINT '--------------------------';
		PRINT 'LOADING TABLES FROM CRM';
		PRINT '--------------------------';

		PRINT '>> TRUNCATING TABLE : bronze.crm_cust_info';
		SET @start_time = GETDATE();
		TRUNCATE TABLE bronze.crm_cust_info;

		PRINT '>> INSERTING TABLE : bronze.crm_cust_info';
		BULK INSERT bronze.crm_cust_info 
		FROM 'C:\Users\USER\Desktop\SQL Learning\sql-data-warehouse-project\sql-data-warehouse-project\datasets\source_crm\cust_info.csv'
		WITH (
			FIRSTROW		= 2,
			FIELDTERMINATOR = ',',
			TABLOCK
		);
		SET @end_time = GETDATE();
		PRINT '>> LOADING DURATION:'+ CAST (DATEDIFF(MILLISECOND, @start_time, @end_time) AS NVARCHAR) + 'ms';
		PRINT '----------------------------------';

		SET @start_time = GETDATE();
		PRINT '>> TRUNCATING TABLE : bronze.crm_prd_info';
		TRUNCATE TABLE bronze.crm_prd_info;

		PRINT '>> INSERTING TABLE : bronze.crm_prd_info';
		BULK INSERT bronze.crm_prd_info
		FROM 'C:\Users\USER\Desktop\SQL Learning\sql-data-warehouse-project\sql-data-warehouse-project\datasets\source_crm\prd_info.csv'
		WITH (
			FIRSTROW		= 2,
			FIELDTERMINATOR = ',',
			TABLOCK
		);
		SET @end_time = GETDATE();
		PRINT '>> LOADING DURATION:'+ CAST (DATEDIFF(MILLISECOND, @start_time, @end_time) AS NVARCHAR) + 'ms';
		PRINT '----------------------------------';


		SET @start_time = GETDATE();
		PRINT '>> TRUNCATING TABLE : bronze.crm_sales_details';
		TRUNCATE TABLE bronze.crm_sales_details;

		PRINT '>> INSERTING TABLE : bronze.crm_sales_details';
		BULK INSERT bronze.crm_sales_details
		FROM 'C:\Users\USER\Desktop\SQL Learning\sql-data-warehouse-project\sql-data-warehouse-project\datasets\source_crm\sales_details.csv'
		WITH (
			FIRSTROW		= 2,
			FIELDTERMINATOR = ',',
			TABLOCK
		);
		SET @end_time = GETDATE();
		PRINT '>> LOADING DURATION:'+ CAST (DATEDIFF(MILLISECOND, @start_time, @end_time) AS NVARCHAR) + 'ms';
		PRINT '----------------------------------';


		PRINT '--------------------------';
		PRINT 'LOADING TABLES FROM ERP';
		PRINT '--------------------------';

		SET @start_time = GETDATE();
		PRINT '>> TRUNCATING TABLE : bronze.erp_cust_az12';
		TRUNCATE TABLE bronze.erp_cust_az12;

		PRINT '>> INSERTING TABLE : bronze.erp_cust_az12';
		BULK INSERT bronze.erp_cust_az12
		FROM 'C:\Users\USER\Desktop\sql-data-warehouse-project\datasets\source_erp\cust_az12.csv'
		WITH (
			FIRSTROW		= 2,
			FIELDTERMINATOR = ',',
			ROWTERMINATOR   = '0x0a',
			TABLOCK,
			ERRORFILE		= 'C:\Users\USER\Desktop\sql-data-warehouse-project\datasets\source_erp\cust_error.log'

		);
		SET @end_time = GETDATE();
		PRINT '>> LOADING DURATION:'+ CAST (DATEDIFF(MILLISECOND, @start_time, @end_time) AS NVARCHAR) + 'ms';
		PRINT '----------------------------------';


		SET @start_time = GETDATE();
		PRINT '>> TRUNCATING TABLE : bronze.erp_loc_a101';
		TRUNCATE TABLE bronze.erp_loc_a101;

		PRINT '>> INSERTING TABLE : bronze.erp_loc_a101';
		BULK INSERT bronze.erp_loc_a101
		FROM 'C:\Users\USER\Desktop\sql-data-warehouse-project\datasets\source_erp\loc_a101.csv'
		WITH (
			FIRSTROW		= 2,
			FIELDTERMINATOR = ',',
			TABLOCK
		);
		SET @end_time = GETDATE();
		PRINT '>> LOADING DURATION:'+ CAST (DATEDIFF(MILLISECOND, @start_time, @end_time) AS NVARCHAR) + 'ms';
		PRINT '----------------------------------';


		SET @start_time = GETDATE();
		PRINT '>> TRUNCATING TABLE : bronze.erp_px_cat_g1v2';
		TRUNCATE TABLE bronze.erp_px_cat_g1v2;

		PRINT '>> INSERTING TABLE : bronze.erp_px_cat_g1v2';
		BULK INSERT bronze.erp_px_cat_g1v2
		FROM 'C:\Users\USER\Desktop\sql-data-warehouse-project\datasets\source_erp\px_cat_g1v2.csv'
		WITH (
			FIRSTROW		= 2,
			FIELDTERMINATOR = ',',
			TABLOCK
		);
		SET @end_time = GETDATE();
		PRINT '>> LOADING DURATION:'+ CAST (DATEDIFF(MILLISECOND, @start_time, @end_time) AS NVARCHAR) + 'ms';
		PRINT '----------------------------------';

		SET @batch_end_time = GETDATE ();
		PRINT '=================================';
		PRINT 'LOADING BRONZE LAYER IS COMPLETED';
		PRINT 'TOTAL LOADING DURATION :' + CAST(DATEDIFF(MILLISECOND,@batch_start_time,@batch_end_time) AS NVARCHAR) + 'ms';
		PRINT '==================================';

	END TRY
	BEGIN CATCH
		PRINT '=========================================';
		PRINT 'ERROR OCCURED DURING LOADING BRONZE LAYER';
		PRINT 'ERROR MESSAGE' + ERROR_MESSAGE();
		PRINT 'ERROR MESSAGE' + CAST(ERROR_NUMBER() AS NVARCHAR);
		PRINT 'ERROR MESSAGE' + CAST(ERROR_STATE() AS NVARCHAR);
		PRINT '=========================================';
	END CATCH
END
