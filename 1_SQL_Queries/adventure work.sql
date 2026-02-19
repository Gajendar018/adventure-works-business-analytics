CREATE DATABASE Adventure_db;

SELECT COUNT(*) FROM adventureworks_sales_2015;
SELECT COUNT(*) FROM adventureworks_sales_2016;
SELECT COUNT(*) FROM adventureworks_sales_2017;

SELECT 
  COUNT(*) AS total_rows,
  COUNT(orderdate) AS orderdate_not_null,
  COUNT(productkey) AS product_not_null,
  COUNT(customerkey) AS customer_not_null
FROM adventureworks_sales_2017;


CREATE VIEW vw_sales_all AS
SELECT *, 2015 AS sales_year FROM adventureworks_sales_2015
UNION ALL
SELECT *, 2016 AS sales_year FROM adventureworks_sales_2016
UNION ALL
SELECT *, 2017 AS sales_year FROM adventureworks_sales_2017;


SELECT sales_year, COUNT(*) 
FROM vw_sales_all
GROUP BY sales_year;


DESCRIBE adventureworks_territories;

CREATE VIEW vw_sales_analysis AS
SELECT
    s.OrderDate,
    s.OrderNumber,
    s.ProductKey,
    s.CustomerKey,
    s.TerritoryKey,

    p.ProductName,
    pc.CategoryName,
    ps.SubcategoryName,

    CONCAT(c.FirstName, ' ', c.LastName) AS CustomerName,

    t.Country,
    t.Region,
    t.Continent,

    s.OrderQuantity,
    p.ProductPrice,
    p.ProductCost,

    -- DERIVED METRICS (IMPORTANT)
    (s.OrderQuantity * p.ProductPrice) AS Revenue,
    (s.OrderQuantity * p.ProductCost) AS Cost,
    ((s.OrderQuantity * p.ProductPrice) - (s.OrderQuantity * p.ProductCost)) AS Profit

FROM vw_sales_all s
LEFT JOIN adventureworks_products p
       ON s.ProductKey = p.ProductKey
LEFT JOIN adventureworks_product_subcategories ps
       ON p.ProductSubcategoryKey = ps.ProductSubcategoryKey
LEFT JOIN adventureworks_product_categories pc
       ON ps.ProductCategoryKey = pc.ProductCategoryKey
LEFT JOIN adventureworks_customers c
       ON s.CustomerKey = c.CustomerKey
LEFT JOIN adventureworks_territories t
       ON s.TerritoryKey = t.SalesTerritoryKey;


SELECT * 
FROM vw_sales_analysis 
LIMIT 10;

SELECT
    YEAR(OrderDate) AS Year,
    ROUND(SUM(Revenue), 2) AS TotalRevenue,
    ROUND(SUM(Profit), 2) AS TotalProfit
FROM vw_sales_analysis
GROUP BY YEAR(OrderDate)
ORDER BY Year;


SELECT
    CategoryName,
    ROUND(SUM(Revenue), 2) AS Revenue,
    ROUND(SUM(Profit), 2) AS Profit,
    ROUND(SUM(Profit) / SUM(Revenue) * 100, 2) AS ProfitMarginPercent
FROM vw_sales_analysis
GROUP BY CategoryName
ORDER BY Revenue DESC;


SELECT
    ProductName,
    ROUND(SUM(Revenue), 2) AS Revenue,
    ROUND(SUM(Profit), 2) AS Profit
FROM vw_sales_analysis
GROUP BY ProductName
ORDER BY Revenue DESC
LIMIT 10;



CREATE VIEW vw_sales_analysis_final AS
SELECT
    *,
    STR_TO_DATE(OrderDate, '%m/%d/%Y') AS OrderDate_Clean
FROM vw_sales_analysis_clean;



SELECT
    ProductName,
    ROUND(SUM(Revenue), 2) AS Revenue
FROM vw_sales_analysis
GROUP BY ProductName
ORDER BY Revenue ASC
LIMIT 10;



SELECT
    CustomerKey,
    CustomerName,
    ROUND(SUM(Revenue), 2) AS LifetimeRevenue
FROM vw_sales_analysis
GROUP BY CustomerKey, CustomerName
ORDER BY LifetimeRevenue DESC;



SELECT
    CustomerSegment,
    COUNT(*) AS CustomerCount,
    ROUND(SUM(LifetimeRevenue), 2) AS SegmentRevenue
FROM (
    SELECT
        CustomerKey,
        SUM(Revenue) AS LifetimeRevenue,
        CASE
            WHEN SUM(Revenue) < 5000 THEN 'Low'
            WHEN SUM(Revenue) BETWEEN 5000 AND 20000 THEN 'Mid'
            ELSE 'High'
        END AS CustomerSegment
    FROM vw_sales_analysis
    GROUP BY CustomerKey
) t
GROUP BY CustomerSegment;



SELECT
    Country,
    ROUND(SUM(Revenue), 2) AS Revenue,
    ROUND(SUM(Profit), 2) AS Profit
FROM vw_sales_analysis
GROUP BY Country
ORDER BY Revenue DESC;


SELECT
    Region,
    ROUND(SUM(Revenue), 2) AS Revenue,
    ROUND(SUM(Profit), 2) AS Profit,
    ROUND(SUM(Profit) / SUM(Revenue) * 100, 2) AS ProfitMarginPercent
FROM vw_sales_analysis
GROUP BY Region
ORDER BY ProfitMarginPercent DESC;


SELECT
    MONTH(OrderDate) AS Month,
    ROUND(SUM(Revenue), 2) AS Revenue
FROM vw_sales_analysis
GROUP BY MONTH(OrderDate)
ORDER BY Month;

SELECT
    ROUND(
        (SUM(Revenue) /
        (SELECT SUM(Revenue) FROM vw_sales_analysis_final)) * 100
    , 2) AS TopProductsRevenuePercent
FROM (
    SELECT ProductName, SUM(Revenue) AS Revenue
    FROM vw_sales_analysis_final
    GROUP BY ProductName
    ORDER BY Revenue DESC
    LIMIT 5
) t;


SELECT
    YEAR(OrderDate) AS Year,
    QUARTER(OrderDate) AS Quarter,
    ROUND(SUM(Revenue), 2) AS Revenue
FROM vw_sales_analysis
GROUP BY YEAR(OrderDate), QUARTER(OrderDate)
ORDER BY Year, Quarter;




SELECT
    CustomerType,
    COUNT(DISTINCT CustomerKey) AS Customers,
    ROUND(SUM(Revenue), 2) AS Revenue
FROM (
    SELECT
        CustomerKey,
        Revenue,
        CASE
            WHEN COUNT(*) OVER (PARTITION BY CustomerKey) = 1 THEN 'New'
            ELSE 'Returning'
        END AS CustomerType
    FROM vw_sales_analysis
) t
GROUP BY CustomerType;


SELECT
    ROUND(SUM(Revenue) / COUNT(DISTINCT OrderNumber), 2) AS AvgOrderValue
FROM vw_sales_analysis;


SELECT
    Country,
    ROUND(SUM(Revenue) / COUNT(DISTINCT OrderNumber), 2) AS AvgOrderValue
FROM vw_sales_analysis
GROUP BY Country
ORDER BY AvgOrderValue DESC;



SELECT
    p.ProductName,
    SUM(r.ReturnQuantity) AS TotalReturns
FROM adventureworks_returns r
JOIN adventureworks_products p
     ON r.ProductKey = p.ProductKey
GROUP BY p.ProductName
ORDER BY TotalReturns DESC;



SELECT 
    SUM(Revenue) AS TopProductsRevenue
FROM (
    SELECT 
        ProductName,
        SUM(Revenue) AS Revenue
    FROM vw_sales_analysis
    GROUP BY ProductName
    ORDER BY Revenue DESC
    LIMIT 5
) t;




CREATE VIEW vw_sales_analysis_clean AS
SELECT
    OrderDate,
    OrderNumber,
    ProductKey,
    CustomerKey,
    TerritoryKey,

    ProductName,
    CategoryName,
    SubcategoryName,
    CustomerName,
    Country,
    Region,
    Continent,

    OrderQuantity,

    ROUND(ProductPrice, 2) AS ProductPrice,
    ROUND(ProductCost, 2) AS ProductCost,

    ROUND(Revenue, 2) AS Revenue,
    ROUND(Cost, 2) AS Cost,
    ROUND(Profit, 2) AS Profit

FROM vw_sales_analysis;


SELECT *
FROM vw_sales_analysis_clean
LIMIT 10;

SELECT
    p.ProductName,
    SUM(r.ReturnQuantity) AS Returns,
    SUM(s.OrderQuantity) AS SoldQty,
    ROUND(SUM(r.ReturnQuantity) / SUM(s.OrderQuantity) * 100, 2) AS ReturnRate
FROM adventureworks_returns r
JOIN adventureworks_products p ON r.ProductKey = p.ProductKey
JOIN vw_sales_analysis_final s ON p.ProductKey = s.ProductKey
GROUP BY p.ProductName
HAVING SoldQty > 50
ORDER BY ReturnRate DESC;


WITH sales_qty AS (
    SELECT
        ProductKey,
        SUM(OrderQuantity) AS SoldQty
    FROM vw_sales_analysis_final
    GROUP BY ProductKey
),
returns_qty AS (
    SELECT
        ProductKey,
        SUM(ReturnQuantity) AS Returns
    FROM adventureworks_returns
    GROUP BY ProductKey
)
SELECT
    p.ProductName,
    r.Returns,
    s.SoldQty,
    ROUND(r.Returns / s.SoldQty * 100, 2) AS ReturnRate
FROM sales_qty s
JOIN returns_qty r ON s.ProductKey = r.ProductKey
JOIN adventureworks_products p ON s.ProductKey = p.ProductKey
WHERE s.SoldQty > 50
ORDER BY ReturnRate DESC;



SELECT
    COUNT(*) AS TopProductsCount
FROM (
    SELECT ProductName,
           SUM(Revenue) AS Revenue,
           SUM(SUM(Revenue)) OVER (ORDER BY SUM(Revenue) DESC)
           /
           (SELECT SUM(Revenue) FROM vw_sales_analysis_final) AS CumulativeShare
    FROM vw_sales_analysis_final
    GROUP BY ProductName
) t
WHERE CumulativeShare <= 0.8;
