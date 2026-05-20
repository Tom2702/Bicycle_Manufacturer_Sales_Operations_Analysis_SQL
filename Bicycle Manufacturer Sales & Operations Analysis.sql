-- Query 01: Calculate quantity of items, sales value and order quantity by subcategory in the last 12 months
WITH latest_date AS (
    SELECT
        MAX(DATE(ModifiedDate)) AS max_date
    FROM `adventureworks2019.Sales.SalesOrderDetail`
)
SELECT
    FORMAT_DATE('%b %Y', DATE_TRUNC(DATE(sales_detail.ModifiedDate), MONTH)) AS period,
    subcategory.Name AS category,
    SUM(sales_detail.OrderQty) AS qty,
    SUM(sales_detail.LineTotal) AS line_total,
    COUNT(DISTINCT sales_detail.SalesOrderID) AS order_qty
FROM `adventureworks2019.Sales.SalesOrderDetail` AS sales_detail
JOIN `adventureworks2019.Production.Product` AS product
    ON sales_detail.ProductID = product.ProductID
JOIN `adventureworks2019.Production.ProductSubcategory` AS subcategory
    ON SAFE_CAST(product.ProductSubcategoryID AS INT64) = subcategory.ProductSubcategoryID
CROSS JOIN latest_date
WHERE DATE(sales_detail.ModifiedDate) BETWEEN DATE_SUB(latest_date.max_date, INTERVAL 12 MONTH) AND latest_date.max_date
GROUP BY
    DATE_TRUNC(DATE(sales_detail.ModifiedDate), MONTH),
    period,
    category
ORDER BY
    DATE_TRUNC(DATE(sales_detail.ModifiedDate), MONTH) DESC,
    category;


-- Query 02: Calculate YoY growth rate by subcategory and return top 3 highest growth rates
WITH yearly_quantity AS (
    SELECT
        EXTRACT(YEAR FROM DATE(sales_detail.ModifiedDate)) AS year,
        subcategory.Name AS category,
        SUM(sales_detail.OrderQty) AS qty_item
    FROM `adventureworks2019.Sales.SalesOrderDetail` AS sales_detail
    JOIN `adventureworks2019.Production.Product` AS product
        ON sales_detail.ProductID = product.ProductID
    JOIN `adventureworks2019.Production.ProductSubcategory` AS subcategory
        ON SAFE_CAST(product.ProductSubcategoryID AS INT64) = subcategory.ProductSubcategoryID
    GROUP BY
        year,
        category
),
growth_rate AS (
    SELECT
        year,
        category,
        qty_item,
        LAG(qty_item) OVER (
            PARTITION BY category
            ORDER BY year
        ) AS prv_qty
    FROM yearly_quantity
)
SELECT
    category AS cat_name,
    qty_item,
    prv_qty,
    ROUND(SAFE_DIVIDE(qty_item, prv_qty) - 1, 2) AS qty_diff
FROM growth_rate
WHERE prv_qty IS NOT NULL
ORDER BY qty_diff DESC
LIMIT 3;


-- Query 03: Rank top 3 territories with the biggest order quantity for each year
WITH territory_order AS (
    SELECT
        EXTRACT(YEAR FROM DATE(order_header.ModifiedDate)) AS year,
        order_header.TerritoryID AS territory_id,
        SUM(sales_detail.OrderQty) AS order_quantity
    FROM `adventureworks2019.Sales.SalesOrderDetail` AS sales_detail
    JOIN `adventureworks2019.Sales.SalesOrderHeader` AS order_header
        ON sales_detail.SalesOrderID = order_header.SalesOrderID
    GROUP BY
        year,
        territory_id
),
ranked_territory AS (
    SELECT
        year,
        territory_id,
        order_quantity,
        DENSE_RANK() OVER (
            PARTITION BY year
            ORDER BY order_quantity DESC
        ) AS rank_no
    FROM territory_order
)
SELECT
    year,
    territory_id,
    order_quantity,
    rank_no
FROM ranked_territory
WHERE rank_no <= 3
ORDER BY
    year DESC,
    rank_no,
    territory_id;


-- Query 04: Calculate total seasonal discount cost by subcategory
SELECT
    EXTRACT(YEAR FROM DATE(sales_detail.ModifiedDate)) AS year,
    subcategory.Name AS subcategory_name,
    SUM(sales_detail.OrderQty * special_offer.DiscountPct * sales_detail.UnitPrice) AS total_discount_cost
FROM `adventureworks2019.Sales.SalesOrderDetail` AS sales_detail
JOIN `adventureworks2019.Production.Product` AS product
    ON sales_detail.ProductID = product.ProductID
JOIN `adventureworks2019.Production.ProductSubcategory` AS subcategory
    ON SAFE_CAST(product.ProductSubcategoryID AS INT64) = subcategory.ProductSubcategoryID
JOIN `adventureworks2019.Sales.SpecialOffer` AS special_offer
    ON sales_detail.SpecialOfferID = special_offer.SpecialOfferID
WHERE LOWER(special_offer.Type) LIKE '%seasonal discount%'
GROUP BY
    year,
    subcategory_name
ORDER BY
    year,
    subcategory_name;


-- Query 05: Retention cohort of customers in 2014 with successfully shipped orders
WITH shipped_orders AS (
    SELECT DISTINCT
        CustomerID AS customer_id,
        EXTRACT(MONTH FROM DATE(ModifiedDate)) AS order_month
    FROM `adventureworks2019.Sales.SalesOrderHeader`
    WHERE EXTRACT(YEAR FROM DATE(ModifiedDate)) = 2014
        AND Status = 5
        AND CustomerID IS NOT NULL
),
first_order AS (
    SELECT
        customer_id,
        MIN(order_month) AS month_join
    FROM shipped_orders
    GROUP BY customer_id
),
month_gap AS (
    SELECT
        first_order.month_join,
        shipped_orders.order_month - first_order.month_join AS month_diff_no,
        shipped_orders.customer_id
    FROM shipped_orders
    JOIN first_order
        ON shipped_orders.customer_id = first_order.customer_id
)
SELECT
    month_join,
    CONCAT('M-', month_diff_no) AS month_diff,
    COUNT(DISTINCT customer_id) AS customer_cnt
FROM month_gap
GROUP BY
    month_join,
    month_diff_no
ORDER BY
    month_join,
    month_diff_no;


-- Query 06: Trend of stock level and MoM percentage difference by product in 2011
WITH monthly_stock AS (
    SELECT
        product.Name AS product_name,
        EXTRACT(MONTH FROM DATE(work_order.ModifiedDate)) AS month,
        EXTRACT(YEAR FROM DATE(work_order.ModifiedDate)) AS year,
        SUM(work_order.StockedQty) AS stock_current
    FROM `adventureworks2019.Production.WorkOrder` AS work_order
    JOIN `adventureworks2019.Production.Product` AS product
        ON work_order.ProductID = product.ProductID
    WHERE EXTRACT(YEAR FROM DATE(work_order.ModifiedDate)) = 2011
    GROUP BY
        product_name,
        month,
        year
),
stock_with_previous AS (
    SELECT
        product_name,
        month,
        year,
        stock_current,
        LAG(stock_current) OVER (
            PARTITION BY product_name
            ORDER BY year, month
        ) AS stock_prv
    FROM monthly_stock
)
SELECT
    product_name,
    month,
    year,
    stock_current,
    stock_prv,
    COALESCE(ROUND((SAFE_DIVIDE(stock_current, stock_prv) - 1) * 100, 1), 0) AS diff_pct
FROM stock_with_previous
ORDER BY
    product_name,
    year,
    month DESC;


-- Query 07: Calculate sales-to-stock ratio in 2011 by product and month
WITH sales_info AS (
    SELECT
        EXTRACT(MONTH FROM DATE(sales_detail.ModifiedDate)) AS month,
        EXTRACT(YEAR FROM DATE(sales_detail.ModifiedDate)) AS year,
        product.ProductID AS product_id,
        product.Name AS product_name,
        SUM(sales_detail.OrderQty) AS order_qty
    FROM `adventureworks2019.Sales.SalesOrderDetail` AS sales_detail
    JOIN `adventureworks2019.Production.Product` AS product
        ON sales_detail.ProductID = product.ProductID
    WHERE EXTRACT(YEAR FROM DATE(sales_detail.ModifiedDate)) = 2011
    GROUP BY
        month,
        year,
        product_id,
        product_name
),
stock_info AS (
    SELECT
        EXTRACT(MONTH FROM DATE(work_order.ModifiedDate)) AS month,
        EXTRACT(YEAR FROM DATE(work_order.ModifiedDate)) AS year,
        product.ProductID AS product_id,
        product.Name AS product_name,
        SUM(work_order.StockedQty) AS stock_qty
    FROM `adventureworks2019.Production.WorkOrder` AS work_order
    JOIN `adventureworks2019.Production.Product` AS product
        ON work_order.ProductID = product.ProductID
    WHERE EXTRACT(YEAR FROM DATE(work_order.ModifiedDate)) = 2011
    GROUP BY
        month,
        year,
        product_id,
        product_name
)
SELECT
    COALESCE(stock_info.month, sales_info.month) AS month,
    COALESCE(stock_info.year, sales_info.year) AS year,
    COALESCE(stock_info.product_id, sales_info.product_id) AS product_id,
    COALESCE(stock_info.product_name, sales_info.product_name) AS name,
    COALESCE(stock_info.stock_qty, 0) AS stock_qty,
    COALESCE(sales_info.order_qty, 0) AS order_qty,
    COALESCE(
        ROUND(SAFE_DIVIDE(COALESCE(sales_info.order_qty, 0), COALESCE(stock_info.stock_qty, 0)), 1),
        0
    ) AS ratio
FROM stock_info
FULL OUTER JOIN sales_info
    ON stock_info.month = sales_info.month
    AND stock_info.year = sales_info.year
    AND stock_info.product_id = sales_info.product_id
ORDER BY
    month DESC,
    ratio DESC;


-- Query 08: Calculate number of purchase orders and value at pending status in 2014
SELECT
    EXTRACT(YEAR FROM DATE(ModifiedDate)) AS year,
    Status AS status,
    COUNT(DISTINCT PurchaseOrderID) AS order_cnt,
    SUM(TotalDue) AS value
FROM `adventureworks2019.Purchasing.PurchaseOrderHeader`
WHERE EXTRACT(YEAR FROM DATE(ModifiedDate)) = 2014
    AND Status = 1
GROUP BY
    year,
    status
ORDER BY
    year,
    status;
