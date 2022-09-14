/*
CAPSTONE PROJECT 2	: Relational Database and MS Excel Dashboard

TITLE				: E-COMMERCE CUSTOMER CHURN PREDICTION

DATA SOURCE			: https://www.kaggle.com/code/wonderdavid/e-commerce-customer-churn-prediction
*/

/*	CREATE DATABASE Capstone_Project	*/
CREATE DATABASE Capstone_Project;

/*	IMPORT ECommerceMaster.csv	
	Right-click Database -> Select Task -> Import Flat File -> ECommerceMaster.csv	*/

/*	RENAME ECommerceMaster TABLE TO Master	
	Right-click ECommerceMaster TABLE -> Rename -> Master	*/

/*	CREATE TABLE Customer	*/
CREATE TABLE dbo.Customer
(
	CustomerID					NVARCHAR(10)	PRIMARY KEY,
	Gender						NCHAR(10)		NOT NULL, 
	MaritalStatus				NCHAR(20), 
	CityTier					INT , 
	WarehouseToHome				INT, 
	NumberOfDeviceRegistered	INT
);


/*	INSERT INTO TABLE Customer	*/
INSERT	INTO dbo.Customer
		SELECT CustomerID, Gender, MaritalStatus, CityTier, WarehouseToHome, NumberOfDeviceRegistered
		FROM Master;


/*	CREATE TABLE LoginDevice	*/
CREATE TABLE dbo.LoginDevice
(
	LoginDeviceID		NCHAR(5)		PRIMARY KEY,
	LoginDeviceName		NVARCHAR(50)	UNIQUE
);


/*	INSERT INTO TABLE LoginDevice	*/
INSERT INTO dbo.LoginDevice (LoginDeviceID, LoginDeviceName)
VALUES		('L01','Computer'),
			('L02','Mobile Phone');


/*	CREATE TABLE PaymentMode	*/
CREATE TABLE dbo.PaymentMode
(
	PaymentModeID		NCHAR(5)		PRIMARY KEY,
	PaymentModeName		NVARCHAR(50)	UNIQUE
);


/*	INSERT INTO TABLE PaymentMode	*/
INSERT INTO dbo.PaymentMode (PaymentModeID, PaymentModeName)
VALUES		('P01','Cash On Delivery'),
			('P02','Credit Card'),
			('P03','Debit Card'),
			('P04','E-Wallet'),
			('P05','Unified Payments Interface');


/*	CREATE TABLE OrderCategory	*/
CREATE TABLE dbo.OrderCategory
(
	OrderCategoryID		NCHAR(5)		PRIMARY KEY,
	OrderCatagoryName	NVARCHAR(50)	UNIQUE
);


/*	INSERT INTO TABLE OrderCategory	*/
INSERT INTO dbo.OrderCategory (OrderCategoryID, OrderCatagoryName)
VALUES		('C01','Fashion'),
			('C02','Grocery'),
			('C03','Laptop & Accessory'),
			('C04','Mobile'),
			('C05','Others');


/*	CREATE TABLE TransactionInsight	*/
CREATE TABLE dbo.TransactionInsight
(
	TransInsightID			INT				IDENTITY(1,1) PRIMARY KEY,
	CustomerID				NVARCHAR(10)	FOREIGN KEY REFERENCES dbo.Customer(CustomerID),
	PreferredLoginDevice	NCHAR(5)		FOREIGN KEY REFERENCES dbo.LoginDevice(LoginDeviceID),
	PreferredPaymentMode	NCHAR(5)		FOREIGN KEY REFERENCES dbo.PaymentMode(PaymentModeID),
	PreferredOrderCat		NCHAR(5)		FOREIGN KEY REFERENCES dbo.OrderCategory(OrderCategoryID),
	Churn					INT,
	Tenure					FLOAT,
	HourSpendOnApp			FLOAT,
	SatisfactionScore		INT,
	Complain				INT,
	OrderHikeFrmPrev		FLOAT,
	CouponUsed				FLOAT,
	OrderCount				FLOAT,
	DaySinceLastOrder		FLOAT,
	CashBackAmt				FLOAT
);


/*	INSERT INTO TABLE TransactionInsight	*/
INSERT INTO dbo.TransactionInsight
(			
			CustomerID, 
			Churn, 
			Tenure, 
			HourSpendOnApp, 
			SatisfactionScore,
			Complain, 
			OrderHikeFrmPrev, 
			CouponUsed, 
			OrderCount, 
			DaySinceLastOrder, 
			CashBackAmt
)
SELECT		CustomerID, 
			Churn, 
			Tenure,  
			HourSpendOnApp, 
			SatisfactionScore,
			Complain, 
			OrderAmountHikeFromlastYear, 
			CouponUsed, 
			OrderCount, 
			DaySinceLastOrder, 
			CashbackAmount
FROM dbo.Master;


/*	POPULATE FOREIGN KEY COLUMNS IN TABLE TransactionInsight	*/

DECLARE @CustID		NVARCHAR(10)= NULL;
DECLARE @LoginDevID	VARCHAR(5)	= NULL;
DECLARE @OrderCatID	VARCHAR(5)	= NULL;
DECLARE @PayModeID	VARCHAR(5)	= NULL;
DECLARE @Iter		BIGINT		= 0;
DECLARE @RowCnt		BIGINT		= 0; 

SELECT	@RowCnt = COUNT(0) FROM Master;

SELECT	ROW_NUMBER() OVER (ORDER BY CustomerID) as row_num,
		CustomerID
		INTO temp_table
		FROM Master;

WHILE	@Iter <= @RowCnt
BEGIN
		SELECT	@CustID = temp_table.CustomerID 
		FROM	temp_table
		WHERE	temp_table.row_num = @Iter;

		SELECT	@LoginDevID = LoginDevice.LoginDeviceID
		FROM	LoginDevice
		JOIN	Master 
		ON		LoginDevice.LoginDeviceName = Master.PreferredLoginDevice
		WHERE	Master.CustomerID = @CustID
		
		SELECT	@OrderCatID = OrderCategory.OrderCategoryID
		FROM	OrderCategory
		JOIN	Master 
		ON		OrderCategory.OrderCatagoryName = Master.PreferedOrderCat
		WHERE	Master.CustomerID = @CustID
		
		SELECT	@PayModeID = PaymentMode.PaymentModeID
		FROM	PaymentMode
		JOIN	Master 
		ON		PaymentMode.PaymentModeName = Master.PreferredPaymentMode
		WHERE	Master.CustomerID = @CustID

		UPDATE	TransactionInsight
		SET		PreferredLoginDevice = @LoginDevID,
				PreferredOrderCat	 = @OrderCatID,
				PreferredPaymentMode = @PayModeID
		WHERE	CustomerID = @CustID;
			
		SET @CustID		= NULL;
		SET @LoginDevID = NULL;
		SET @OrderCatID = NULL;
		SET @PayModeID	= NULL;

		SET @Iter += 1;
END

DROP TABLE temp_table;

-----------------------------------------------------------------------------------------------
/*	DECLARE VARIABLES FOR QUERIES	*/

DECLARE @Retained VARCHAR(10) = 'Retained';
DECLARE @Churned  VARCHAR(10) = 'Churned';

/*	QUERY 1	: RETAINED VS CHURNED	*/

IF EXISTS(SELECT * FROM INFORMATION_SCHEMA.TABLES 
		  WHERE TABLE_NAME = 'Query1' AND TABLE_SCHEMA = 'dbo')
DROP TABLE		dbo.Query1;

DECLARE @RetainedCount	INT = 0;
DECLARE @ChurnCount		INT = 0;

SELECT @RetainedCount = COUNT(Churn) FROM TransactionInsight WHERE Churn = 0;
SELECT @ChurnCount	  = COUNT(Churn) FROM TransactionInsight WHERE Churn = 1;

SELECT @RetainedCount AS 'Retained', @ChurnCount AS 'Churned' INTO Query1;


/*	QUERY 2 : TENURE DISTRIBUTION OF RETAINED VS CHURNED CUSTOMERS	*/

IF EXISTS(SELECT * FROM INFORMATION_SCHEMA.TABLES 
		  WHERE TABLE_NAME = 'Query2' AND TABLE_SCHEMA = 'dbo')
DROP TABLE		dbo.Query2;

	SELECT		@Retained AS 'CustomerStatus',
				COUNT(TransactionInsight.Churn) AS 'CustomerCount',
				SUM(DISTINCT(TransactionInsight.Tenure)) AS 'Total Tenure'
	INTO		Query2
	FROM		TransactionInsight
	WHERE		TransactionInsight.Churn = 0
	GROUP BY	TransactionInsight.Tenure, TransactionInsight.Churn;
		
INSERT INTO		Query2
	SELECT		@Churned AS 'CustomerStatus',
				COUNT(TransactionInsight.Churn) AS 'CustomerCount',
				SUM(DISTINCT(TransactionInsight.Tenure)) AS 'Total Tenure'
	FROM		TransactionInsight
	WHERE		TransactionInsight.Churn = 1
	GROUP BY	TransactionInsight.Tenure, TransactionInsight.Churn;
		

/*	QUERY 3 : ORDER DISTRIBUTION AMONG CUSTOMERS	*/

IF EXISTS(SELECT * FROM INFORMATION_SCHEMA.TABLES 
		  WHERE TABLE_NAME = 'Query3' AND TABLE_SCHEMA = 'dbo')
	DROP TABLE dbo.Query3;

	SELECT		@Retained AS 'CustomerStatus',
				COUNT(TransactionInsight.Churn) AS 'CustomerCount',
				MAX(TransactionInsight.PreferredOrderCat) AS 'OrderCategory',
				OrderCategory.OrderCatagoryName AS 'OrderCategoryName',
				SUM(TransactionInsight.OrderCount) AS 'TotalOrder'
	INTO		Query3
	FROM		TransactionInsight
	JOIN		OrderCategory
	ON			TransactionInsight.PreferredOrderCat = OrderCategory.OrderCategoryID
	WHERE		TransactionInsight.Churn = 0
	GROUP BY	OrderCategory.OrderCatagoryName, 
				TransactionInsight.PreferredOrderCat, TransactionInsight.Churn
	ORDER BY	TransactionInsight.PreferredOrderCat, TransactionInsight.Churn;

INSERT INTO		Query3
	SELECT		@Churned AS 'CustomerStatus',
				COUNT(TransactionInsight.Churn) AS 'CustomerCount',
				MAX(TransactionInsight.PreferredOrderCat) AS 'OrderCategory',
				OrderCategory.OrderCatagoryName AS 'OrderCategoryName',
				SUM(TransactionInsight.OrderCount) AS 'TotalOrder'
	FROM		TransactionInsight
	JOIN		OrderCategory
	ON			TransactionInsight.PreferredOrderCat = OrderCategory.OrderCategoryID
	WHERE		TransactionInsight.Churn = 1
	GROUP BY	OrderCategory.OrderCatagoryName, 
				TransactionInsight.PreferredOrderCat, TransactionInsight.Churn
	ORDER BY	TransactionInsight.PreferredOrderCat;


/*	QUERY 4 : RECENCY OF CUSTOMER ORDERS	*/

IF EXISTS(SELECT * FROM INFORMATION_SCHEMA.TABLES 
			WHERE TABLE_NAME = 'Query4' AND TABLE_SCHEMA = 'dbo')
DROP TABLE	dbo.Query4;

	SELECT		DISTINCT TransactionInsight.DaySinceLastOrder AS 'Days',
				COUNT(TransactionInsight.DaySinceLastOrder) AS 'Recency',
				@Retained AS 'CustomerStatus'
	INTO		Query4
	FROM		TransactionInsight
	WHERE		TransactionInsight.Churn = 0
	GROUP BY	TransactionInsight.DaySinceLastOrder
	ORDER BY	TransactionInsight.DaySinceLastOrder ASC;

INSERT INTO		Query4
	SELECT		DISTINCT TransactionInsight.DaySinceLastOrder AS 'Days',
				COUNT(TransactionInsight.DaySinceLastOrder) AS 'Recency',
				@Churned AS 'CustomerStatus'
	FROM		TransactionInsight
	WHERE		TransactionInsight.Churn = 1
	GROUP BY	TransactionInsight.DaySinceLastOrder
	ORDER BY	TransactionInsight.DaySinceLastOrder ASC;


/*	QUERY 5 : RETAINED VS CHURNED CUSTOMER WITH CASHBACK	*/

IF EXISTS(SELECT * FROM INFORMATION_SCHEMA.TABLES 
			WHERE TABLE_NAME = 'Query5' AND TABLE_SCHEMA = 'dbo')
DROP TABLE	dbo.Query5;

	SELECT		@Retained AS 'CustomerStatus',
				COUNT(TransactionInsight.Churn) AS 'CustomerCount',
				ROUND(TransactionInsight.CashBackAmt,0) AS 'CashBackAmount'
	INTO		Query5
	FROM		TransactionInsight
	WHERE		TransactionInsight.Churn = 0
	GROUP BY	TransactionInsight.CashBackAmt
	ORDER BY	TransactionInsight.CashBackAmt;

INSERT INTO		Query5
	SELECT		@Churned AS 'CustomerStatus',
				COUNT(TransactionInsight.Churn) AS 'CustomerCount',
				ROUND(TransactionInsight.CashBackAmt,0) AS 'CashBackAmount'
	FROM		TransactionInsight
	WHERE		TransactionInsight.Churn = 1
	GROUP BY	TransactionInsight.CashBackAmt
	ORDER BY	TransactionInsight.CashBackAmt;


/*	QUERY 6 : CUSTOMER SATISFACTION SCORE DISTRIBUTION	*/

IF EXISTS(SELECT * FROM INFORMATION_SCHEMA.TABLES 
			WHERE TABLE_NAME = 'Query6' AND TABLE_SCHEMA = 'dbo')
DROP TABLE	dbo.Query6;

	SELECT		@Retained AS 'CustomerStatus',
				COUNT(TransactionInsight.Churn) AS 'CustomerCount',
				TransactionInsight.SatisfactionScore
	INTO		Query6
	FROM		TransactionInsight
	WHERE		TransactionInsight.Churn = 0
	GROUP BY	TransactionInsight.SatisfactionScore
	ORDER BY	TransactionInsight.SatisfactionScore;

INSERT INTO		Query6
	SELECT		@Churned AS 'CustomerStatus',
				COUNT(TransactionInsight.Churn) AS 'CustomerCount',
				TransactionInsight.SatisfactionScore
	FROM		TransactionInsight
	WHERE		TransactionInsight.Churn = 1
	GROUP BY	TransactionInsight.SatisfactionScore
	ORDER BY	TransactionInsight.SatisfactionScore;


/*	QUERY 7 : CUSTOMER COMPLAINT DISTRIBUTION	*/

IF EXISTS(SELECT * FROM INFORMATION_SCHEMA.TABLES 
			WHERE TABLE_NAME = 'Query7' AND TABLE_SCHEMA = 'dbo')
DROP TABLE	dbo.Query7;

	SELECT		@Retained AS 'CustomerStatus',
				COUNT(TransactionInsight.Churn) AS 'CustomerCount',
				TransactionInsight.Complain
	INTO		Query7
	FROM		TransactionInsight
	WHERE		TransactionInsight.Churn = 0
	GROUP BY	TransactionInsight.Complain
	ORDER BY	TransactionInsight.Complain;

INSERT INTO		Query7
	SELECT		@Churned AS 'CustomerStatus',
				COUNT(TransactionInsight.Churn) AS 'CustomerCount',
				TransactionInsight.Complain
	FROM		TransactionInsight
	WHERE		TransactionInsight.Churn = 1
	GROUP BY	TransactionInsight.Complain
	ORDER BY	TransactionInsight.Complain;


/*	QUERY 8 : CUSTOMER GENDER DISTRIBUTION	*/

IF EXISTS(SELECT * FROM INFORMATION_SCHEMA.TABLES 
			WHERE TABLE_NAME = 'Query8' AND TABLE_SCHEMA = 'dbo')
DROP TABLE	dbo.Query8;

	SELECT		@Retained AS 'CustomerStatus',
				COUNT(TransactionInsight.Churn) AS 'CustomerCount',
				Customer.Gender
	INTO		Query8
	FROM		TransactionInsight
	JOIN		Customer
	ON			TransactionInsight.CustomerID = Customer.CustomerID
	WHERE		TransactionInsight.Churn = 0
	GROUP BY	Customer.Gender;

INSERT INTO Query8
	SELECT		@Churned AS 'CustomerStatus',
				COUNT(TransactionInsight.Churn) AS 'CustomerCount',
				Customer.Gender
	FROM		TransactionInsight
	JOIN		Customer
	ON			TransactionInsight.CustomerID = Customer.CustomerID
	WHERE		TransactionInsight.Churn = 1
	GROUP BY	Customer.Gender;


/*	QUERY 9 : CUSTOMER MARITAL STATUS DISTRIBUTION	*/

IF EXISTS(SELECT * FROM INFORMATION_SCHEMA.TABLES 
			WHERE TABLE_NAME = 'Query9' AND TABLE_SCHEMA = 'dbo')
DROP TABLE	dbo.Query9;

	SELECT		@Retained AS 'CustomerStatus',
				COUNT(TransactionInsight.Churn) AS 'CustomerCount',
				Customer.MaritalStatus
	INTO		Query9
	FROM		TransactionInsight
	JOIN		Customer
	ON			TransactionInsight.CustomerID = Customer.CustomerID
	WHERE		TransactionInsight.Churn = 0
	GROUP BY	Customer.MaritalStatus
	ORDER BY	Customer.MaritalStatus DESC;

INSERT INTO Query9
	SELECT		@Churned AS 'CustomerStatus',
				COUNT(TransactionInsight.Churn) AS 'CustomerCount',
				Customer.MaritalStatus
	FROM		TransactionInsight
	JOIN		Customer
	ON			TransactionInsight.CustomerID = Customer.CustomerID
	WHERE		TransactionInsight.Churn = 1
	GROUP BY	Customer.MaritalStatus
	ORDER BY	Customer.MaritalStatus DESC;


/*	QUERY 10 : CUSTOMER HOURS SPENT ON APP DISTRIBUTION	*/

IF EXISTS(SELECT * FROM INFORMATION_SCHEMA.TABLES 
			WHERE TABLE_NAME = 'Query10' AND TABLE_SCHEMA = 'dbo')
DROP TABLE	dbo.Query10;

	SELECT		@Retained AS 'CustomerStatus',
				COUNT(TransactionInsight.Churn) AS 'CustomerCount',
				TransactionInsight.HourSpendOnApp
	INTO		Query10
	FROM		TransactionInsight
	WHERE		TransactionInsight.Churn = 0
	GROUP BY	TransactionInsight.HourSpendOnApp
	ORDER BY	TransactionInsight.HourSpendOnApp;

INSERT INTO		Query10
	SELECT		@Churned AS 'CustomerStatus',
				COUNT(TransactionInsight.Churn) AS 'CustomerCount',
				TransactionInsight.HourSpendOnApp
	FROM		TransactionInsight
	WHERE		TransactionInsight.Churn = 1
	GROUP BY	TransactionInsight.HourSpendOnApp
	ORDER BY	TransactionInsight.HourSpendOnApp;


/*	QUERY 12 : WAREHOUSE AND CUSTOMER ADDRESS PROXIMITY DISTRIBUTION	*/

IF EXISTS(SELECT * FROM INFORMATION_SCHEMA.TABLES 
			WHERE TABLE_NAME = 'Query12' AND TABLE_SCHEMA = 'dbo')
DROP TABLE	dbo.Query12;

	SELECT		@Retained AS 'CustomerStatus',
				COUNT(TransactionInsight.Churn) AS 'CustomerCount',
				Customer.WarehouseToHome
	INTO		Query12
	FROM		TransactionInsight
	JOIN		Customer
	ON			TransactionInsight.CustomerID = Customer.CustomerID
	WHERE		TransactionInsight.Churn = 0
	GROUP BY	Customer.WarehouseToHome;

INSERT INTO		Query12
	SELECT		@Churned AS 'CustomerStatus',
				COUNT(TransactionInsight.Churn) AS 'CustomerCount',
				Customer.WarehouseToHome
	FROM		TransactionInsight
	JOIN		Customer
	ON			TransactionInsight.CustomerID = Customer.CustomerID
	WHERE		TransactionInsight.Churn = 1
	GROUP BY	Customer.WarehouseToHome;

/*	END OF QUERIES	*/
