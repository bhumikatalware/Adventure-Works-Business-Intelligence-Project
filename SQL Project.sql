USE sales_db;
SHOW TABLES;
SELECT COUNT(*) FROM DimCustomer;

-- QUESTION 0: UNION FACT TABLES

DROP TABLE IF EXISTS FactSales;
CREATE TABLE FactSales AS
SELECT * FROM FactInternetSales
UNION ALL
SELECT * FROM FactInternetSalesNew;

-- QUESTION 1: JOIN PRODUCT TABLE

DROP TABLE IF EXISTS Sales_Product;
CREATE TABLE Sales_Product AS
SELECT
    fs.*,
    p.EnglishProductName AS ProductName,
    p.StandardCost
FROM FactSales fs
LEFT JOIN DimProduct p
    ON fs.ProductKey = p.ProductKey;

-- QUESTION 2: JOIN CUSTOMER TABLE

SELECT 
    -- 1. Create the Full Name from the Customer table
    TRIM(CONCAT(c.FirstName, ' ', IFNULL(CONCAT(c.MiddleName, ' '), ''), c.LastName)) AS CustomerFullName,
    -- 2. Pull UnitPrice from the Sales table
    s.UnitPrice,
    -- 3. Include other identifying columns
    s.CustomerKey,
    s.ProductKey,
    s.SalesOrderNumber
FROM (
    -- Combine both Sales sheets
    SELECT * FROM FactInternetSales
    UNION ALL
    SELECT * FROM FactInternetSalesNew
) AS s
LEFT JOIN DimCustomer AS c 
    ON TRIM(CAST(s.CustomerKey AS CHAR)) = TRIM(CAST(c.CustomerKey AS CHAR));
    

-- QUESTION 3: DATE CALCULATIONS

-- A 
SELECT 
    OrderDateKey,
    LEFT(OrderDateKey, 4) AS OrderYear
FROM FactSales;

-- B
SELECT 
    OrderDateKey,
    MONTH(STR_TO_DATE(CAST(OrderDateKey AS CHAR), '%Y%m%d')) AS MonthNumber
FROM FactSales;

-- C
SELECT 
    OrderDateKey,
    MONTHNAME(STR_TO_DATE(CAST(OrderDateKey AS CHAR), '%Y%m%d')) AS MonthFullName
FROM FactSales;

-- D
SELECT 
    OrderDateKey,
    CONCAT('Q', QUARTER(STR_TO_DATE(CAST(OrderDateKey AS CHAR), '%Y%m%d'))) AS QuarterLabel
FROM FactSales;

-- E
SELECT 
    OrderDateKey,
    CONCAT(LEFT(OrderDateKey, 4), '-', SUBSTRING(OrderDateKey, 5, 2)) AS YearMonth
FROM FactSales;

-- F
SELECT 
    OrderDateKey,
    WEEKDAY(STR_TO_DATE(CAST(OrderDateKey AS CHAR), '%Y%m%d')) AS WeekdayIndex
FROM FactSales;

-- G
SELECT 
    s.OrderDateKey,
    d.EnglishDayNameOfWeek AS WeekdayName
FROM FactSales s
JOIN DimDate d ON s.OrderDateKey = d.DateKey;

-- H
SELECT 
    OrderDateKey,
    -- Step 1: Get the Calendar Month
    -- Step 2: Use MOD math to shift the start to July
    (MOD(MONTH(STR_TO_DATE(CAST(OrderDateKey AS CHAR), '%Y%m%d')) + 5, 12) + 1) AS FinancialMonth
FROM FactSales;

-- I
SELECT 
    OrderDateKey,
    CASE 
        WHEN MONTH(STR_TO_DATE(OrderDateKey, '%Y%m%d')) IN (7, 8, 9) THEN 3
        WHEN MONTH(STR_TO_DATE(OrderDateKey, '%Y%m%d')) IN (10, 11, 12) THEN 4
        WHEN MONTH(STR_TO_DATE(OrderDateKey, '%Y%m%d')) IN (1, 2, 3) THEN 1
        WHEN MONTH(STR_TO_DATE(OrderDateKey, '%Y%m%d')) IN (4, 5, 6) THEN 2
    END AS FinancialQuarter
FROM FactSales;
 
-- QUESTION 4,5,6, -- Total_sales, Total_production_cost & Total_profit

SELECT 
    ROUND(SUM(SalesAmount), 2) AS Total_Sales,
    ROUND(SUM(TotalProductCost), 2) AS Total_Production_Cost,
    ROUND(SUM(SalesAmount) - SUM(TotalProductCost), 2) AS Total_Profit
FROM FactSales;

-- QUESTION 7: MONTH-WISE SALES

SELECT
    Year,
    Month,
    SUM(SalesAmount) AS TotalSales
FROM Final_Sales
GROUP BY Year, Month
ORDER BY Year, Month;

-- QUESTION 8: YEAR-WISE SALES

SELECT
    Year,
    SUM(SalesAmount) AS YearlySales
FROM Final_Sales
GROUP BY Year
ORDER BY Year;

-- QUESTION 9: MONTH-WISE SALES 

SELECT
    Month,
    SUM(SalesAmount) AS MonthlySales
FROM Final_Sales
GROUP BY Month
ORDER BY Month;

-- QUESTION 10: QUARTER-WISE SALES 

SELECT
    Quarter,
    SUM(SalesAmount) AS QuarterlySales
FROM Final_Sales
GROUP BY Quarter
ORDER BY Quarter;

-- QUESTION 11: SALESAMOUNT and PRODUCTION COST 

SELECT
    YEAR(STR_TO_DATE(fs.OrderDateKey, '%Y%m%d')) AS Year,
    SUM(fs.UnitPrice * fs.OrderQuantity) AS TotalSalesAmount,
    SUM(p.StandardCost * fs.OrderQuantity) AS TotalProductionCost
FROM FactSales fs
LEFT JOIN DimProduct p
    ON fs.ProductKey = p.ProductKey
GROUP BY Year
ORDER BY Year;

-- QUESTION 12: Product Performance

SELECT
    p.EnglishProductName AS ProductName,
    SUM(fs.UnitPrice * fs.OrderQuantity) AS TotalSales,
    SUM(p.StandardCost * fs.OrderQuantity) AS TotalProductionCost,
    SUM((fs.UnitPrice * fs.OrderQuantity) -
        (p.StandardCost * fs.OrderQuantity)) AS Profit
FROM FactSales fs
LEFT JOIN DimProduct p
    ON fs.ProductKey = p.ProductKey
GROUP BY p.EnglishProductName
ORDER BY TotalSales DESC;

-- QUESTION 12: Customer Performance

SELECT
    CONCAT(c.FirstName, ' ', c.LastName) AS CustomerName,
    SUM(fs.UnitPrice * fs.OrderQuantity) AS TotalSales,
    COUNT(DISTINCT fs.SalesOrderNumber) AS TotalOrders,
    SUM((fs.UnitPrice * fs.OrderQuantity) -
        (p.StandardCost * fs.OrderQuantity)) AS Profit
FROM FactSales fs
LEFT JOIN DimCustomer c
    ON fs.CustomerKey = c.CustomerKey
LEFT JOIN DimProduct p
    ON fs.ProductKey = p.ProductKey
GROUP BY CustomerName
ORDER BY TotalSales DESC;

-- QUESTION 12: Region Performance

SELECT
    CASE fs.SalesTerritoryKey
        WHEN 1 THEN 'North America'
        WHEN 2 THEN 'Europe'
        WHEN 3 THEN 'Asia'
        ELSE 'Other'
    END AS Region,
    SUM(fs.UnitPrice * fs.OrderQuantity) AS TotalSales
FROM FactSales fs
GROUP BY fs.SalesTerritoryKey;


-- QUESTION 12: OVERALL Performance

SELECT
    SUM(fs.UnitPrice * fs.OrderQuantity) AS TotalSales,
    SUM(p.StandardCost * fs.OrderQuantity) AS TotalProductionCost,
    SUM((fs.UnitPrice * fs.OrderQuantity) -
        (p.StandardCost * fs.OrderQuantity)) AS TotalProfit
FROM FactSales fs
LEFT JOIN DimProduct p
    ON fs.ProductKey = p.ProductKey;
